package;
using SizeOf;
import io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;

class InlineArrayBuilder
{
#if macro
    static var typeMap : Map<Int,ComplexType> = new Map();

    static private function buildClass(name, type_T, itemSize:Int)
    {
        var i = macro this.offset + $v{itemSize} * index;
        var getter = switch itemSize {
            case 1: macro (this.buffer).get      ($i);
            case 2: macro (this.buffer).getInt16 ($i);
            case 4: macro (this.buffer).getInt32 ($i);
            case 8: macro (this.buffer).getInt64 ($i);
            case s: macro (this.buffer).sub      ($i, $v{s});
        }
        var sizeOf = macro this.length * $v{itemSize};
        var self : TypePath = {name:name, pack:[]};
        return macro class $name extends InlineArray.ReadOnlyBufferSlice implements InlineArray.IInlineArray<$type_T>
        {
            inline public function new (buffer, offset, length) super(buffer, offset, length);

            @:pure inline public function get    (index)      return $getter;
            @:pure inline public function stride ()           return $v{itemSize};
            @:pure inline public function sizeOf ()           return $sizeOf;
            @:pure inline public function slice  (index, end) return new $self(this.buffer, $i, end);

            inline public function bytes () return (this.buffer).sub(this.offset, $sizeOf);
        }
    }

    static public function build () : ComplexType
    {
        trace("Local type: "+Context.getLocalType());
        // trace("Local expected: "+Context.getExpectedType());
        switch (Context.getLocalType()) {
            case TInst(n, [type_T]):
                switch type_T {
                    default:
                    case TMono(_): // Ignore
                        Context.error("Cannot infer type of InlineArray.T ... please specify", Context.currentPos());
                }

                var itemSize = type_T.sizeOf();
                var ct = typeMap.get(itemSize);
                if (ct != null) {
                    trace("Reuse type: " + ct);
                    return ct;
                }
                // Store a copy of @:genericBuild, remove it
                var genericBuildMeta = n.get().meta.extract(":genericBuild")[0];
                n.get().meta.remove(genericBuildMeta.name);
                // Define type
                var name = '${n}_${itemSize}';
                var cl = buildClass(name, TypeTools.toComplexType(type_T), itemSize);
                haxe.macro.Context.defineType(cl);
                // Re-add @:genericBuild
                n.get().meta.add(genericBuildMeta.name, genericBuildMeta.params, genericBuildMeta.pos);
                // trace(haxe.macro.Context.getType("InlineArray"));

                var ct = TPath({ name: cl.name, pack: cl.pack });
                typeMap.set(itemSize, ct);
                return ct;

            case t:
                Context.error("Class expected", Context.currentPos());
        }
        return null;
    }
#end
}
