package;
using SizeOf;
import io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

#if !macro @:genericBuild(InlineArrayBuilder.build()) #end
extern interface InlineArray <T> extends InlineArrayAPI <T> {}

interface InlineArrayAPI <T>
{
    public var itemsBytes (get,never) : ReadOnlyMemory;
    public var length (default,null) : PositiveInt;
    public var sizeOf (get,never) : PositiveInt;

    public function nth    (index : Int) : T;
    public function slice  (start : Int, end : Int) : InlineArrayAPI<T>;
}

interface FixedSizeItems <T> extends InlineArrayAPI <T>
{
    public var stride (get,never) : PositiveInt;
}

interface VariableSizeItems extends InlineArrayAPI <ReadOnlyMemory>
{
    public var sizeOfIndex (get,never) : PositiveInt;
    public var sizeOfValues (get,never) : PositiveInt;

    public function sizeAt (index : PositiveInt) : PositiveInt;
    public function slice  (start : Int, end : Int) : VariableSizeItems;
}

class ReadOnlyBufferSlice
{
    public final buffer : ReadOnlyMemory;
    public final offset : PositiveInt;
    public final length : PositiveInt;

    public inline function new (buffer, offset:PositiveInt, length:PositiveInt) {
        this.buffer = buffer;
        this.offset = offset;
        this.length = length;
    }

    /**
     * Used for calculating 64 byte padding of arrays.
     * @param offset round this offset up to the next 64 byte position
     */
    @:pure public static inline function pad64 (offset:PositiveInt) : PositiveInt {
        return PositiveInt.unsafeCast((offset + 63) & (~63));
    }
}

/**
 * This class purely contains helper functions for macro generated array-access abstract types.
 */
class InlineArraySlice
{
    public static inline function clampStart (index:Int, length:Int) : PositiveInt {
        // trace("index = " + index + " length = " + length);
        if (index < 0) index = length + index;
        else if (index > length) index = length;
        // trace("index after = " + index);
        return PositiveInt.unsafeCast(index);
    }
    public static inline function clampEnd (index:Int, end:Int, length:Int) : PositiveInt {
        // trace("end = " + end);
        end = if (end >= 0) (end > length? length : end) - index; else length - index + end;
        // trace("end mid = " + end);
        if (end < 0) end = 0;
        // trace("end after = " + end);
        return PositiveInt.unsafeCast(end);
    }
}

/**
 * This Iterator base skeleton class is extended by macro generated type specific iterators.
 * Because type A is generic, using constraints such as `A:InlineArrayAPI<T>` is not enough
 * information for ArraySlices to be fully `inline new`'d when iterating over them.
 *
 * Having a type specific iterator helps Haxe compiler to figure out the entire Slice can be inlined.
 */
class InlineArrayIteratorBase <A>
{
	final arr : A;
	final len : Int;
	var i : PositiveInt;

	public inline function new (a, length)
	{
		arr = a;
		len = length;
		i = PositiveInt.unsafeCast(0);
	}

	public inline function hasNext () : Bool return i < len;

    // Implemented in sub class:
	// public inline function next () : T return arr.nth(i++);
}
