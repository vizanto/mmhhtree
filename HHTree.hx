package ;

import io.Bytes;
import haxe.Int32;
import haxe.Int64;
import haxe.io.ArrayBufferView;
import haxe.macro.Expr;

///////////////////////////////////////

class HHTree {
#if !macro
    static public function main() {
        trace("HH");
        // trace("1  => " + Util.pad64(1));
        // trace("2  => " + Util.pad64(2));
        // trace("4  => " + Util.pad64(4));
        // trace("8  => " + Util.pad64(8));
        // trace("17 => " + Util.pad64(17));
        // trace("22 => " + Util.pad64(22));
        // trace("32 => " + Util.pad64(32));
        // trace("60 => " + Util.pad64(60));
        // trace("61 => " + Util.pad64(61));
        // trace("62 => " + Util.pad64(62));
        // trace("63 => " + Util.pad64(63));
        // trace("64 => " + Util.pad64(64));
        // trace("65 => " + Util.pad64(65));
        // trace("66 => " + Util.pad64(66));
        #if java
        var m = java.nio.ByteBuffer.allocate(1024);
        m.order(java.nio.ByteOrder.LITTLE_ENDIAN);
        for (i in 0 ... 100) m.putLong(1+i);
        #else
        var m = haxe.io.Bytes.alloc(1024);
        for (i in 0 ... 100) m.setInt64(i*8, 1+i);
        #end
        var a : InlineArray<Int64> = new InlineArray<Int64>(new ReadOnlyMemory(m), 16, 100);
        trace("size = " + a.sizeOf());
        trace("stride = " + a.stride());
        trace("0 = " + m.get(0) + " " + m.get(1) + " " + m.get(2) + " " + m.get(3) + " " + m.get(4) + " " + m.get(5) + " " + m.get(6) + " " + m.get(7));
        trace("1 = " + a.get(0) + " " + a.get(1) + " " + a.get(2) + " " + a.get(3) + " " + a.get(4) + " " + a.get(5) + " " + a.get(6) + " " + a.get(7));
        trace("bytes = " + m);
        trace("2 = " + a.bytes());
        trace("3 = " + a.bytes().sub(0, 8).get(7));
        trace("4 = " + a.slice(10, 90).get(0));
    }
#end
}

///////////////////////////////////////

abstract Int8 (#if java java.types.Int8 #else Int #end) {}

abstract Timestamp(Int) {

}
abstract Attribute(Int) {

}

class AVT {
    var buffer : Bytes;
    var attribute : Attribute;
    var valueRef : ValueRef;
    var txInstant : Timestamp;

    // casting function, type provided by attribute
    //function value() return attribute.readValue(valueRef);
}

//////////////////////////////////////////

class Util {
    static public inline function pad64 (offset:Int) {
        return (offset + 63) & (~63);
    }
}

/*
    ValueIndex layout:

    length    : Int32;
    hashIndex : Int32;
    --or--
    longValue : Int64;
*/

/*
    ValueRef layout:

    length : Int32;
    data   : byte[length] serialized value | 64 bytes Blake2;

    if (length <= 64)
    value  :
*/
class ValueRef
{
    var buffer : Bytes;
    var offset : Int;
    var cached : Dynamic;

    public inline function length () return buffer.getInt32(offset);

    public inline function getValue (attribute : Attribute)
    {
        // if (cached == null) {
        //     var l = length();
        //     cached = if (l <= 60) attribute.toRuntimeValue(buffer, offset, l)
        //              else ValueTable.find(buffer, offset, l);
        // }
        return cached;
    }
}

/*
    Arrays with frequent key lookups should be sorted in Eytzinger layout. (Breadth First Search)
    "6.1 Eytzinger is Best - Not only is searching in an Eytzinger layout fast, it is simple and compact to implement"

    Downside of Eytzinger layout: no fast sorted order traversal.

    EAVT segment layout:

    numDatoms     : Int32 < size;
    txInstants    : Int64[numDatoms] + padding;
    valueOffsets  : Int32[numDatoms + 1] + padding;

    numAttributes : Int32 <= numDatoms;
    if numAttributes < numDatoms:
        attributeVals : Int32[numAttributes + 1] + padding;
    attributes    : Int64[numAttributes] + padding;

    numEntities   : Int32 <= numAttributes;
    entityAttrs   : Int32[numEntities + 1] + padding; Ranges of attributes per entity
    entities      : Int64[numEntities] + padding;

    blake2        : 64 byte Blake2;

    // Segment trailer
    numEntities   : Int32 <= numAttributes;
    pAttributes   : pointer to numAttributes, end of valueBytes;
    numDatoms     : Int32 < size;

    size          : Int32;
    EAVT_TYPE_ID  : Int32 = 0xEAF70001;
*/
typedef EAVT_01_Layout = {
    // Header
    @:invariant_readForwards(_ == 0xEAF70001)
    private var header_id : Int32;

    // Data
    @:invariant_readForwards(_ >= 1)
    public var numDatoms : Int32;

    @:pad(64)
    @:length(numDatoms)
    public var txInstants : InlineArray<Int64>;

    // @:pad(64)
    @:length(numDatoms)
    /**
     * Size:    valueOffsets[$-1] - valueOffsets[0]
     * at most: INLINE_VALUE_SIZE_LIMIT * numDatoms
     */
    public var valueBytes : InlineVariableBytesArray;

    @:invariant_readForwards(_ >= 1 && _ <= numDatoms)
    public var numAttributes : Int32;

    @:calculateOffsetFromBufferEnd @:pad(64) // pad for SIMD registers
    @:length(numDatoms > numAttributes? numAttributes + 1 : 0)
    public var attributeValues : InlineArray<Int32>;

    @:calculateOffsetFromBufferEnd @:pad(64) // pad for SIMD registers
    @:length(numAttributes)
    public var attributes : InlineArray<Int64>;

    @:invariant_readForwards(_ >= 1 && _ <= numAttributes)
    public var numEntities : Int32;

    @:calculateOffsetFromBufferEnd @:pad(64) // pad for SIMD registers
    @:length(numEntities + 1)
    public var entityAttributes : InlineArray<Int32>;

    @:calculateOffsetFromBufferEnd @:pad(64) // pad for SIMD registers
    @:length(numEntities)
    public var entities : InlineArray<Int64>;

    @:calculateOffsetFromBufferEnd @:pad(64) // pad for SIMD registers
    @:length(64)
    @:invariant_readForwards(matchesBlake2(_))
    public var blake2 : InlineArray<Byte>;

    // Footer

    @:zero_size_if(numEntities < 8)
    @:invariant_readForwards(_ == entities[numEntities - 1])
    @:calculateOffsetFromBufferEnd
    public var maxEntity : Int64;

    @:zero_size_if(numEntities < 8)
    @:invariant_readForwards(_ == entities[numEntities >> 1])
    @:calculateOffsetFromBufferEnd
    public var medianEntity : Int64;

    @:zero_size_if(numEntities < 8)
    @:invariant_readForwards(_ == entities[0])
    @:calculateOffsetFromBufferEnd
    public var minEntity : Int64;

    @:invariant_readForwards(_ == numEntities)
    @:calculateOffsetFromBufferEnd
    private var footer_numEntities : Int32;

    @:invariant_readForwards(_ == numAttributes)
    @:calculateOffsetFromBufferEnd
    private var footer_numAttributes : Int32;

    @:invariant_readForwards(_ == numDatoms)
    @:calculateOffsetFromBufferEnd
    private var footer_numDatoms : Int32;

    // To load this layout from disk:
    //   Dispatch on footer_id, read size then check footer_id == buffer[buffer.pos - size]
    @:invariant_readForwards(_ == header_id)
    @:calculateOffsetFromBufferEnd
    private var footer_id : Int32;

    @:invariant_readForwards(_ == reader.bytesRead - 4)
    @:calculateOffsetFromBufferEnd
    public var size : Int32;
};

/* Useful metadata
 @:dce                  : Forces dead code elimination even when -dce full is
                          not specified

 @:mergeBlock           : Merge the annotated block into the current scope

 @:noCompletion         : Prevents the compiler from suggesting completion on
                          this field
*/
// @:build(StructReader.build((_ : EAVT_01_Layout)))
@:dce
@:analyzer(optimize)
@:analyzer(const_propagation)
@:analyzer(copy_propagation)
@:analyzer(local_dce)
@:analyzer(fusion)
@:analyzer(user_var_fusion)
@:analyzer(purity_inference)
@:notNull
abstract EAVT_01 (ReadOnlyMemory)
{
    // @:pure inline function get_numEntities () return footer_numEntities;
    // @:pure inline function get_numAttributes () return footer_numAttributes;
    // @:pure inline function get_numDatoms () return footer_numDatoms;

/*
    @:pure inline function offsetOf_maxEntity ()
        return offsetOf_medianEntity - sizeOf_maxEntity;
        return buffer.length - sizeOf_size(4) - sizeOf_footer_id(4) - sizeOf_footer_numDatoms(4)
            - sizeOf_footer_numAttributes(4) - sizeOf_numEntities(4)
            - sizeOf_minEntity(numEntities < 8? 0 : 8) - sizeOf_medianEntity(numEntities < 8? 0 : 8)
            - 8 (sizeOf_maxEntity)

    @:pure inline function get_maxEntity () return sizeof(maxEntity) == 0? entities[-1] : this.getInt64(offsetOf(maxEntity));
*/
    inline function new (buffer) this = buffer;

/*
    static public function readFooter(buffer, location) : EAVT_01 {
        var size = buffer.getInt32(location);
        var slice = buffer.slice(location - size, location + sizeof(footer_id));
        return new EAVT_01(new ReadOnlyMemory(slice));
    }
*/

/*
    static public function readForwards(reader : Blake2ComputingInputStream) {
        var data : EAVT_01_Layout;
        inline function matchesBlake2() return reader.blake2 == data.blake2;

        checkInvariants(reader, data);
    }
*/
}











abstract EAVT_Segment (Bytes)
{
    ///--- Memory layout specification -------------------------------------///
    static inline var numDatoms_offset = 4;

    /// txInstant
    static inline var txInstant_ELEMENT_SIZE = 8;
    static inline var txInstant_offset = 8;
    static inline function txInstant_end (numDatoms:Int)
        return txInstant_offset + txInstant_ELEMENT_SIZE * numDatoms;


    /// values
    static inline var values_ELEMENT_SIZE = 64;
    static inline function values_offset (numDatoms:Int)
        return Util.pad64(txInstant_end(numDatoms));

    static inline function values_end (numDatoms:Int)
        return values_offset(numDatoms) + values_ELEMENT_SIZE * numDatoms;


    /// attributes
    static inline var attributes_ELEMENT_SIZE = 8;
    static inline function attributes_offset (numDatoms:Int)
        return values_end(numDatoms);

    static inline function attributes_end (numDatoms:Int, numAttributes:Int)
        return attributes_offset(numDatoms) + attributes_ELEMENT_SIZE * numAttributes;


    /// entities
    static inline var entities_ELEMENT_SIZE = 8;
    static inline function entities_offset (numDatoms:Int)
        return values_end(numDatoms);

    static inline function entities_end (numDatoms:Int, numAttributes:Int)
        return entities_offset(numDatoms) + attributes_ELEMENT_SIZE * numAttributes;




    ///--- Segment reading API ---------------------------------------------///

    inline function new (buffer) this = buffer;

    inline function numDatoms () return this.getInt32(numDatoms_offset);

    inline function txInstant (i:Int) {
        var l = numDatoms();
        if (i > l) throw HHTreeError.outOfSegmentBounds;
        return this.getInt32(4 + i);
    }

    inline function value (i:Int) {
        var l = numDatoms();
        if (i > l) throw HHTreeError.outOfSegmentBounds;
        return this.getInt32(4 + i);
    }
}
