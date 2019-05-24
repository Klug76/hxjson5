package;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using haxe.macro.Tools;

class MetaMacroTools
{
	public static inline var json5: String = ":json5";
	public static inline var def: String = ":def";

	public static function find_String(meta: Array<MetadataEntry>): String
	{
		for (m in meta)
		{
			var arr = m.params;
			if ((arr != null) && (arr.length == 1))
			{
				switch(arr[0].expr)
				{
				case EConst(CString(s)):
					return s;
				default:
				}
			}
		}
		return "";
	}

	public static function find_Int(meta: Array<MetadataEntry>): Int
	{
		for (m in meta)
		{
			var arr = m.params;
			if ((arr != null) && (arr.length == 1))
			{
				switch(arr[0].expr)
				{
				case EConst(CInt(s)):
					return Std.parseInt(s);
				default:
				}
			}
		}
		return 0;
	}

	public static function find_Float(meta: Array<MetadataEntry>): Float
	{
		for (m in meta)
		{
			var arr = m.params;
			if ((arr != null) && (arr.length == 1))
			{
				switch(arr[0].expr)
				{
				case EConst(CInt(s)):
					return Std.parseInt(s);
				case EConst(CFloat(s)):
					return Std.parseFloat(s);
				default:
				}
			}
		}
		return 0;
	}

	static public function find_Json_Name(targetDescriptorType: Type): String
	{
		switch(targetDescriptorType)
		{
		case TInst(_.get() => cl, [])://:class
			return find_String(cl.meta.extract(json5));
		case TType(_.get() => tdef, [])://:typedef
			var real_type = targetDescriptorType.follow();
			switch(real_type)
			{
			case TAnonymous(_.get() => tdeftype)://:struct
				return find_String(tdef.meta.extract(json5));
			case TInst(_.get() => cl, [])://:class
				var meta = if (tdef.meta.has(json5)) tdef.meta else cl.meta;
				return find_String(meta.extract(json5));
			default:
				trace(tdef);
			}
		default:
			trace(targetDescriptorType);
		}
		trace("WARNING: unsupported type");
		return "";
	}

	static public function find_Fields(targetDescriptorType: Type): Array<ClassField>
	{
		switch(targetDescriptorType)
		{
		case TInst(_.get() => cl, [])://:class
			return cl.fields.get();
		case TType(_.get() => tdef, [])://:typedef
			var real_type = targetDescriptorType.follow();
			switch(real_type)
			{
			case TAnonymous(_.get() => st)://:struct
				return st.fields;
			case TInst(_.get() => cl, [])://:class
				return cl.fields.get();
			default:
				trace(real_type);
			}
		default:
			trace(targetDescriptorType);
		}
		trace("WARNING: unsupported type");
		return null;
	}
}