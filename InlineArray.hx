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

@:forward(bytes,length,stride,sizeOf,slice)
abstract InlineArrayAccess <T,U:InlineArrayAPI<T>> (U) from U to U
{
    @:arrayAccess inline public function nth (index:Int) : T return this.nth(index);
    inline public function iterator () return new InlineArrayIterator<T,U>(this);

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

@:final class InlineArrayIterator<T,U:InlineArrayAPI<T>>
{
	final arr : U;
	final len : Int;
	var i : Int;

	public inline function new (a:U)
	{
		arr = a;
		len = a.length;
		i = 0;
	}

	public inline function hasNext () : Bool return i < len;
	public inline function next () : T return arr.nth(i++);
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
/*
class SliceArrayView <T> extends ReadOnlyBufferSlice implements IInlineArray<T> {
}

abstract InlineArray <T> (SliceArrayView<T>) {

    static public macro function array <T> (itemType:T, buffer:) : ExprOf<SliceArrayView<T>> {
        trace(expr);
        return macro null;
    }

    @:arrayAccess public inline function get (index:Int) return this.get(index);
}

/*
class InlineArray <T>
{
    public final buffer : ReadOnlyMemory;
    public final offset : Int;
    public final length : Int;

    public inline function new(buffer, offset, length) {
        this.buffer = buffer;
        this.offset = offset;
        this.length = length;
    }

    @:pure public macro function sizeOf (ethis) : ExprOf<Int>
        return macro $ethis.length * $v{stride_of_T(ethis)};

    @:pure public macro function stride (ethis:Expr) : ExprOf<Int>
        return macro $v{stride_of_T(ethis)};

    public macro function bytes (ethis:Expr) : ExprOf<ReadOnlyMemory>
        return macro ($ethis.buffer).sub($ethis.offset, $v{stride_of_T(ethis)} * $ethis.length);

    @:pure public macro function slice (ethis:Expr, start:ExprOf<Int>, length:ExprOf<Int>) : ExprOf<InlineArray<T>> {
        var stride = stride_of_T(ethis);
        var T = TypeTools.toComplexType(type_of_T(ethis));
        return macro {
            var firstByte = $v{stride} * $start;
            if (firstByte < 0 || firstByte > $ethis.length * $v{stride}) throw HHTreeError.outOfSegmentBounds;
            new InlineArray<$T>($ethis.buffer, firstByte, $length);
        }
    }

    @:pure public macro function get (ethis:Expr, index : ExprOf<Int>) : ExprOf<T>
    {
        var stride = stride_of_T(ethis);
        var i = macro $ethis.offset + $v{stride} * $index;
        return switch stride {
            case 1: macro ($ethis.buffer).get      ($i);
            case 4: macro ($ethis.buffer).getInt32 ($i);
            case 8: macro ($ethis.buffer).getInt64 ($i);
            case s: macro ($ethis.buffer).sub      ($i, $v{s});
        }
    }

#if macro
    @:pure static function stride_of_T (ethis:Expr) return type_of_T(ethis).sizeOf();

    @:pure static function type_of_T (ethis:Expr) : haxe.macro.Type
    {
        return switch Context.typeof(ethis) {
            case TInst(n, [t]): trace([ for (field in n.get().fields.get()) field.name + " = " + field.meta.get() ]); t;
            default: Context.error("Class expected", Context.currentPos());
        }
    }
#end
}
*/
