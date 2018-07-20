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
    public var bytes  (get,never) : ReadOnlyMemory;
    public var length (default,null) : Int;
    public var stride (get,never) : Int;
    public var sizeOf (get,never) : Int;

    public function nth    (index : Int) : T;
    public function slice  (from : Int, until : Int) : InlineArrayAPI<T>;
}

class ReadOnlyBufferSlice
{
    public final buffer : ReadOnlyMemory;
    public final offset : Int;
    public final length : Int;

    public inline function new(buffer, offset, length) {
        if (offset < 0) throw "Idiot";
        this.buffer = buffer;
        this.offset = offset;
        this.length = length;
    }
}

/**
 * This class purely contains helper functions for macro generated array-access abstract types.
 */
class InlineArraySlice
{
    public static inline function clampStart (index,length) {
        // trace("index = " + index + " length = " + length);
        if (index < 0) index = length + index;
        else if (index > length) index = length;
        // trace("index after = " + index);
        return index;
    }
    public static inline function clampEnd (index,end,length) {
        // trace("end = " + end);
        end = if (end >= 0) (end > length? length : end) - index; else length - index + end;
        // trace("end mid = " + end);
        if (end < 0) end = 0;
        // trace("end after = " + end);
        return end;
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
	var i : Int;

	public inline function new (a, length)
	{
		arr = a;
		len = length;
		i = 0;
	}

	public inline function hasNext () : Bool return i < len;

    // Implemented in sub class:
	// public inline function next () : T return arr.nth(i++);
}
