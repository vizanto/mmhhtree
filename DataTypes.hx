package;
import haxe.macro.Context;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class DataTypes {
    static var sizes = ['Byte' => 1, 'haxe.Int32' => 4, 'haxe.Int64' => 8];
    // static var typeMap = new Map();

    static public function build()
    {
        switch (Context.getLocalType()) {
            case TInst(n, [t1]):
                // var t = typeMap.get(t1);
                // if (t != null) return t;

                var sub = TypeTools.toString(t1);

                .split('.').join('_');
                var name = '${n}_${sub}';
                trace(name);
                // var cl = macro class $name extends $n {};
                // trace(ExprTools.toString(cl));

            case t:
                Context.error("Class expected", Context.currentPos());
        }
        return null;
    }
}
