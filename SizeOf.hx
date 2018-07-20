package;
import haxe.Int32;
import haxe.Int64;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

class SizeOf_Type
{
    static public function sizeOf (T:haxe.macro.Type)
    {
        var name = TypeTools.toString(T);
        return switch name {
            case "Byte"       : 1;
            case "Int"        : 4;
            case "haxe.Int32" : 4;
            case "haxe.Int64" : 8;
            case unknown:
                var next = TypeTools.followWithAbstracts(T, true);
                trace("Nope: " + T + ". next: " + next);
                if (TypeTools.toString(next) == name)
                    Context.error("No known fixed byte size for type: " + unknown, (macro this).pos);
                else
                    trace("Nope: " + T);
                    sizeOf(next);
        }
    }
}
#end

class SizeOf
{
    // static public macro function sizeOf (ethis:Expr)
    // {
    //     var T = switch Context.typeof(ethis) {
    //         case TInst(n, [t]): Context.toComplexType(t);
    //         default: Context.error("Class expected", Context.currentPos());
    //     }
    //     return macro {var _type_T:$T; (_type_T:SizeOf);};
    // }

    // @:from static inline function sizeof_Byte <T:Byte> (t:T) : SizeOf return cast 1;
    // @:from static inline function sizeof_Int  <T:Int>  (t:T) : SizeOf return cast 4;
    // @:from static inline function sizeof_Int32<T:Int32>(t:T) : SizeOf return cast 4;
    // @:from static inline function sizeof_Int64<T:Int64>(t:T) : SizeOf return cast 8;

    // static public macro function sizeOf (v : Expr) : ExprOf<SizeOf> return macro ($v:SizeOf);
}
