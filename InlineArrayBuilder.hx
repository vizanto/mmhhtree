package;
#if macro
using SizeOf;
using StringTools;
import io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
#end

class InlineArrayBuilder
{
#if macro
    static var typeMap : Map<Int,ComplexType> = new Map();

    static private function buildClass(name, itemSize:Int)
    {
        var stride = macro PositiveInt.safeCast($v{itemSize});
        var i = macro offset + $stride * index;
        var getter = switch itemSize {
            // (buffer) wrapped in parens is done here to help Haxe with inline new:
            case 1: macro (buffer).get      ($i);
            case 2: macro (buffer).getInt16 ($i);
            case 4: macro (buffer).getInt32 ($i);
            case 8: macro (buffer).getInt64 ($i);
            case s: macro new ReadOnlyMemory(buffer).sub($i, $v{s});
        }
        var fakeGetCall = macro { var offset = 0, buffer:Bytes = null, index = 0; $getter; };
        var type_T = TypeTools.toComplexType(Context.typeof(fakeGetCall));
        var self : TypePath = {name:name, pack:[]};
        var type_self = TPath(self);
        var a_name = "A" + name;
        var a_self : TypePath = {name:a_name, pack:self.pack};
        var type_a_self = TPath(a_self);
        var iter_name = name + "_Iterator";
        var iter_self : TypePath = {name:iter_name, pack:self.pack};
        var type_iter_self = TPath(iter_self);
        var sizeOf = macro length * $stride;

        var def = macro class $name extends InlineArray.ReadOnlyBufferSlice implements InlineArray.FixedSizeItems<$type_T>
        {
            // the `inline` part of `inline new` is not inherited from super class
            inline public function new (buffer, offset, length) super(buffer, offset, length);

            @:pure inline public function get (index:PositiveInt) : $type_T
                if (index < length) return $getter; else throw HHTreeError.outOfArrayBounds;

            @:pure inline public function nth (index:Int) return this.get(index);

            public var array (get,never) : $type_a_self;
            @:pure inline function get_array () return this;

            public var itemsBytes (get,never) : ReadOnlyMemory;
            inline function get_itemsBytes () return new ReadOnlyMemory(buffer).sub(this.offset, $sizeOf);

            public var sizeOf (get,never) : PositiveInt;
            @:pure inline function get_sizeOf () return PositiveInt.unsafeCast($sizeOf);

            public inline function iterator () return new $iter_self(this, this.length);

            public var stride (get,never) : PositiveInt;
            @:pure inline public function get_stride () : PositiveInt return $stride;

            inline public function slice (start:Int, end:Int) {
                var index = InlineArray.InlineArraySlice.clampStart(start, this.length);
                var end = InlineArray.InlineArraySlice.clampEnd(index, end, this.length);
                return new $self(new ReadOnlyMemory(buffer), $i, end);
            }
        }
        def.meta.push({name: ":final", pos: def.pos});
        haxe.macro.Context.defineType(def);

        var iter = macro class $iter_name extends InlineArray.InlineArrayIteratorBase<$type_self> {
            // the `inline` part of `inline new` is not inherited from super class
            public inline function new (a : $type_self, length : Int) super(a, length);
        	public inline function next () : $type_T return arr.get(PositiveInt.unsafeCast(i++));
        }
        iter.meta.push({name: ":final", pos: iter.pos});
        haxe.macro.Context.defineType(iter);

        var abs = macro class $a_name {
            // the `inline` part of `inline new` is not inherited from super class
            inline public function new (buffer, offset, length)
                this = new $self(buffer,offset,length);
            @:arrayAccess inline public function get (index:PositiveInt) : $type_T
                return this.get(index);
            @:arrayAccess inline public function nth (index:Int) : $type_T
                return this.nth(index);
            @:arrayAccess inline public function range (range:IntIterator)
                return this.slice(@:privateAccess range.min, @:privateAccess range.max);
        }
        abs.kind = TDAbstract(type_self, [type_self], [type_self]);
        abs.meta = [{name: ":forward", params: [macro itemsBytes, macro iterator, macro length, macro slice, macro stride, macro sizeOf], pos: def.pos}];
        haxe.macro.Context.defineType(abs);

        return {type_T: type_T, abst: a_self, self: self};
    }

    static public function build () : ComplexType
    {
        switch (Context.getLocalType()) {
            case TInst(n, [type_T]):
                switch type_T {
                    default:
                    case TMono(_): // Ignore
                        // return null;
                        Context.error("Cannot infer type of InlineArray.T ... please specify", Context.currentPos());
                }
                // Determine byte size of T
                var itemSize = type_T.sizeOf();
                var ct = typeMap.get(itemSize);
                if (ct != null) {
                    // trace("Reuse type: " + ct);
                    return ct;
                }
                // Define type
                var name = '${n}_${itemSize}';
                var cl = buildClass(name, itemSize), ct = TPath(cl.abst), type_T = cl.type_T;
                // Return Type path
                typeMap.set(itemSize, ct);
                return ct;

            case t:
                Context.error("Class expected", Context.currentPos());
        }
        return null;
    }
#end
}
