package gs.util;

class Signal2<T1, T2> extends SignalBase<T1->T2->Void>
{
	public function fire(t1: T1, t2: T2): Void
	{
		SignalBase.doFire(t1, t2);
	}
}
