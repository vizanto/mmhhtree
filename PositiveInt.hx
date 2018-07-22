package;

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

	static public inline function unsafeCast (knownPositiveInt : Int) : PositiveInt {
		#if debug
		if (knownPositiveInt < 0) throw "BUG: knownPositiveInt = " + knownPositiveInt + ", but should be > 0";
		#end
		return untyped knownPositiveInt;
	}

	@:from static public inline function fromInt (i : Int) : PositiveInt
		return if (i >= 0) untyped i else throw i + " should be > 0";
}
