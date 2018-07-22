package;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
#end

abstract PositiveInt (Int) to Int
{
    @:op(A > B) static function gt( a:PositiveInt, b:Int ) : Bool;
    @:op(A < B) static function lt( a:PositiveInt, b:Int ) : Bool;

    @:op(A * B) static inline function mul( mul_a:PositiveInt, mul_b:PositiveInt ) : PositiveInt {
		return unsafeCast((mul_a:Int) * (mul_b:Int));
	}
    @:op(A + B) static inline function add( add_a:PositiveInt, add_b:PositiveInt ) : PositiveInt {
		return unsafeCast((add_a:Int) + (add_b:Int));
	}

	static public #if !debug inline #end function unsafeCast (knownPositiveInt : Int) : PositiveInt {
		#if debug
		if (knownPositiveInt < 0) throw "BUG: knownPositiveInt = " + knownPositiveInt + ", but should be > 0";
		#end
		return untyped knownPositiveInt;
	}

	@:from static public macro function safeCast (expr:ExprOf<Int>) : Expr
	{
		#if macro
		var literalPositive = try ExprTools.getValue(expr) >= 0 catch (e:Dynamic) false; // {trace(e); false;}
		var runtimeCheck =  if (literalPositive) {
			// trace("Compile time cast:  " + ExprTools.toString(expr) + " which is " + ExprTools.getValue(expr));
			macro {};
		} else {
			// trace("Runtime check cast: " + ExprTools.toString(expr));
			macro if ((n:Int) >= 0) n else throw n + " should be > 0";
		}
		return macro {
			var n : PositiveInt = untyped $expr;
			$runtimeCheck; n;
		}
		#end
	}
}
