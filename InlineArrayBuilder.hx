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
        var def = macro class $name extends InlineArray<$type_T> // extends InlineArray.ReadOnlyBufferSlice implements InlineArray.InlineArrayAPI<$type_T>
        {
            inline public function new (buffer, offset, length) super(buffer, offset, length);

            @:pure inline public function get    (index)      return $getter;
            @:pure inline public function stride ()           return $v{itemSize};
            @:pure inline public function sizeOf ()           return $sizeOf;
            @:pure inline public function slice  (index, end) return new $self(this.buffer, $i, end);

            inline public function bytes () return (this.buffer).sub(this.offset, $sizeOf);
        }

        haxe.macro.Context.defineType(def);
        trace("Defined subclass");
        // var nt = Context.typeof(macro new InlineArray(null,0,0));
        // trace("Got type of base class:" + nt);
        var nt = Context.typeof(macro new $self(null,0,0));
        trace("Got type of new class: " + nt);

        return self;
    }

    static public function build () : ComplexType
    {
        trace("Local type: "+Context.getLocalType());
        trace("Local module: "+Context.getLocalModule());
        // trace("Local module contents: " + Context.getModule("InlineArray"));
        // trace("Local expected: "+Context.getExpectedType());

        switch (Context.getLocalType()) {
            case TInst(n, [type_T]):
                switch type_T {
                    default:
                    case TMono(_): // Ignore
                        // return null;
                        Context.error("Cannot infer type of InlineArray.T ... please specify", Context.currentPos());
                }

                if (Context.getLocalModule().startsWith("InlineArray")) {
                    n.get().meta.remove(":genericBuild");
                    var tp = TPath({ name: "InlineArray", pack: [], params: [TPType(type_T.toComplexType())] });
                    trace("Returning base type: " + tp.toString());
                    return tp;
                }

                var itemSize = type_T.sizeOf();
                var ct = typeMap.get(itemSize);
                if (ct != null) {
                    trace("Reuse type: " + ct);
                    return ct;
                }

                // Store a copy of @:genericBuild, remove it
                var baseType = Context.getModule("InlineArray")[0];
                // Prevent infinite recursion while building this class
                trace("got base: " + baseType);
                var baseType = baseType.getClass();
                baseType.kind = KNormal;
                var genericBuildMeta = baseType.meta.extract(":genericBuild")[0];
                baseType.meta.remove(genericBuildMeta.name);
                trace("Removed metadata");
                trace("baseType: " + baseType);
                trace("baseType meta: " + baseType.meta.get());

                // Evaluate base class
                // var bpath = {name:baseType.name, pack:baseType.pack};
                // var nt = Context.typeof(macro return new $bpath(null,0,0));
                // trace("Got type of base class: " + nt);


                // Define type
                var name = '${n}_${itemSize}';
                var tp = buildClass(name, TypeTools.toComplexType(type_T), itemSize);


                // Re-add @:genericBuild
                baseType.meta.add(genericBuildMeta.name, genericBuildMeta.params, genericBuildMeta.pos);
                trace("Re-added metadata");

                baseType.kind = KGenericBuild;
                // Return Type path
                var ct = TPath(tp);
                typeMap.set(itemSize, ct);
                return ct;

            case t:
                Context.error("Class expected", Context.currentPos());
        }
        return null;
    }
#end
}
