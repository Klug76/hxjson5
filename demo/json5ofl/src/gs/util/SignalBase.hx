package gs.util;


#if macro
import haxe.macro.Expr;
#end

class SignalBase<F>
{
	var fn_ : Array<F> = [];
	var fn_temp_ : Array<F> = [];

	var used_ : Int = 0;
	var state_ : SignalState = SignalState.INACTIVE;

	public function new()
	{}
	
	public function dispose() : Void
	{
		//TODO fix me
	}

	function start() : Void
	{
		if (state_.has(SignalState.ACTIVE))
		{
			return;
		}
		state_.set(SignalState.ACTIVE);
		on_Start();
	}

	function on_Start() : Void
	{}

	function stop() : Void
	{
		if (!state_.has(SignalState.ACTIVE))
		{
			return;
		}
		state_.unset(SignalState.ACTIVE);
		on_Stop();
	}

	function on_Stop() : Void
	{}

	public macro static function doFire(exprs : Array<Expr>) : Expr
	{
		return macro
		{
			if (state_.has(SignalState.FIRE))
				return;
			var count : Int = used_;
			if (0 == count)
				return;
			state_.set(SignalState.FIRE);
			//:make copy
			for (i in 0...count)
			{
				var fn = fn_[i];
				fn_temp_[i] = fn;//:https://haxe.org/manual/std-Array.html: write access in Haxe is unbounded
			}
			for (i in 0...count)
			{
				var fn = fn_temp_[i];
				fn($a { exprs });
			}
			state_.unset(SignalState.FIRE);
		}
	}

	/*
	* add once
	*/
	public function add(fn : F) : Void
	{
		if (fn_.indexOf(fn) < 0)
		{
			fn_[used_++] = fn;//:see below
		}
		start();
	}

	/*
	* remove if have
	*/
	public function remove(fn : F) : Void
	{
		var i : Int = fn_.indexOf(fn);
		if (i >= 0)
		{
			//:swap with last.. may cause re-order.. beware..
			fn_[i] = fn_[--used_];
			fn_[used_] = null;
		}
		if (used_ <= 0)
		{
			stop();
		}
	}
}

