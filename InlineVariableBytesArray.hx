package;
import InlineArray.InlineArrayAPI;
import InlineArray.InlineArraySlice.*;
import InlineArray.VariableSizeItems;
import InlineArray.ReadOnlyBufferSlice;
import InlineArray.ReadOnlyBufferSlice.pad64;

/*
    valueOffsets  : Int32[numDatoms + 1] + padding;
    valueBytes    : Byte[ (valueOffsets[-1] - valueOffsets[0]),
    //                    at most: INLINE_VALUE_SIZE_LIMIT * numDatoms ] + padding;
*/
/**
 * 64-byte padded variable length values (bytes)
 */
class InlineVariableBytesArray extends ReadOnlyBufferSlice implements VariableSizeItems
{
    /**
     * index array of 32-bit offsets
     */
    static inline var stride = 4;

    final valueBytesOffset : PositiveInt;

    public inline function new(buffer, indexOffset, length, valueBytesOffset) {
        super(buffer, indexOffset, length);
        this.valueBytesOffset = valueBytesOffset;
    }

    public var itemsBytes (get,never) : ReadOnlyMemory;
    inline function get_itemsBytes () return new ReadOnlyMemory(buffer).sub(valueBytesOffset, sizeOfValues);

    public var sizeOf (get,never) : PositiveInt;
    @:pure public inline function get_sizeOf () return sizeOfIndex + sizeOfValues;

    public var sizeOfIndex (get,never) : PositiveInt;
    @:pure public inline function get_sizeOfIndex () return length * stride;

    public var sizeOfValues (get,never) : PositiveInt;
    @:pure public inline function get_sizeOfValues () return PositiveInt.unsafeCast(getValueOffset(length) - getValueOffset(0));

    /**
     * Get the relative position of the first byte of a value.
     * @param index which value to get an offset for
     * @return position relative to valueBytesOffset
     */
    @:pure public inline function getValueOffset (index:PositiveInt) : PositiveInt
        return PositiveInt.unsafeCast(buffer.getInt32(offset + index * stride));

    @:pure inline public function get (index:PositiveInt) {
        if (index > length) throw HHTreeError.outOfSegmentBounds;
        var valueStart = getValueOffset(index);
        var valueEnd   = getValueOffset(index + 1);
        var valueSlice = getValueOffset(0);
        // trace('index = ${index}, valueSlice = ${valueSlice}, valueStart = ${valueStart}, valueEnd = ${valueEnd}');
        return buffer.sub(valueBytesOffset - valueSlice + valueStart, valueEnd - valueStart);
    }

    @:pure inline public function nth (index:Int) return this.get(index);

    @:pure public inline function sizeAt (index:PositiveInt) : PositiveInt
        return PositiveInt.unsafeCast(getValueOffset(index+1) - getValueOffset(index));

    inline public function slice (start:Int, end:Int)
    {
        var index = clampStart(start, this.length);
        var end = clampEnd(index, end, this.length);
        var valueOffset = this.valueBytesOffset + getValueOffset(index);
        // trace('index = ${index}, end = ${end}, valueOffset = ${valueOffset}');
        return new InlineVariableBytesArray(new ReadOnlyMemory(buffer), index * stride, end, valueOffset);
    }
}
