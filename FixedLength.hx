package;
import io.Bytes;
import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;

// typedef FixedString <@:const Length:Int> = FixedLength <Length, String>;

abstract FixedLength <@:const Length:Int /*, T */> (Bytes /* T */)
{
	@:from static public macro function from (str : ExprOf<Bytes>) : Expr return fixedLengthCast(str);
	static public macro function fixedLength (str : ExprOf<Bytes>, length:Int) : Expr return fixedLengthCast(str, length);

	#if macro
	static public function parameters(type : haxe.macro.Type) return switch (type) {
		case TAbstract(n, [TInst(length, _) /*, type_T */]):
			var value = switch length.get().kind {
				case KExpr(e): e.getValue();
				default:
					Context.error(n + " first type parameter must be a constant", Context.currentPos());
			}
			{length: value /*, type_T*/};
		case other:
			Context.error("Unexpected: " + other, Context.currentPos());
	}

	static public function fixedLengthCast (str : ExprOf<Bytes>, ?length:Int) : Expr {
		var p = parameters(Context.getExpectedType());
		var length:Int = length != null? length : p.length;
		var lengthParam = TPExpr(macro $v{length});
		var returnType = TPath({name: "FixedLength", pack: [], params: [lengthParam]});

		var throwError = macro throw /* $v{TypeTools.toString(p[1])} + */ ".length is " + str.length + " but should be <= " + $v{length};
		throwError.pos = Context.currentPos();

		var expr = macro {
			var str:Bytes = $str;
			if (str.length > $v{length}) $throwError;
			else cast(str, $returnType);
		}
		expr.pos = Context.currentPos();
		return expr;
	}
	#end
}
