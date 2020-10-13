package gs.util;

#if (air || sys)

#if air
import flash.filesystem.File;
import flash.errors.Error;
#else
import sys.io.File;
import sys.FileSystem;
#end
import haxe.Timer;

private class PathUtil
{
	public static function path_Is_Relative(fname: String): Bool
	{
		return (fname.indexOf(":/") < 0) && (fname.indexOf("/") != 0);
	}

	public static function path_Add_Slash(fpath: String): String
	{
		if (!StringTools.endsWith(fpath, "/"))
			fpath += "/";
		return fpath;
	}
}

private class FileInfo
{
	public var key_: String;
	public var filename_: String;
	public var filepath_: String;
	public var exists_: Bool = false;
	public var last_modified_time_: Float = 0;
#if air
	public var file_: File;
#end

	public function new(key: String, fname: String, basedir: String)
	{
		key_ = key;
		filename_ = fname;
		if (PathUtil.path_Is_Relative(fname))
			filepath_ = basedir + fname;
		else
			filepath_ = fname;
#if air
		file_ = new File(filepath_);
#end
		update();
	}

	public function update()
	{
#if air
		exists_ = file_.exists;
#else
		exists_ = FileSystem.exists(filepath_);
#end
//trace("*********** " + key_ + " exists=" + exists_);
		if (!exists_)
			return;
#if air
		try
		{
			last_modified_time_ = file_.modificationDate.getTime();
		}
		catch (_: Error)
		{
			last_modified_time_ = 0;
		}
		//trace("*********** " + file_.nativePath + " time=" + last_modified_time_);
#else
		last_modified_time_ = FileSystem.stat(filepath_).mtime.getTime();
		//trace("*********** " + (filepath_) + " time=" + last_modified_time_);
#end
	}

}

class FsWatcher
{
	public var signal_changed_ = new Signal2<String, String>();
	public var elapse_ms_: Int = 1000;

	var base_dir_: String = "";
	var file_list_: Array<FileInfo> = [];
	var file_map_ = new Map<String, FileInfo>();
	var timer_: Timer = null;

	public function new()
	{}

	public function set_Base_Dir(fpath: Null<String>): Void
	{
		if (null == fpath)
		{
			fpath = "";
		}
		else if (PathUtil.path_Is_Relative(fpath))
		{
#if air
			base_dir_ = "file:///" + File.applicationDirectory.nativePath;
#else
			var pr = Sys.programPath();
			if (pr != null)
			{
				var arr = pr.split("\\").join("/").split("/");
				arr.pop();
				base_dir_ = arr.join("/");
			}
#end
		}
		base_dir_ = PathUtil.path_Add_Slash(base_dir_);
		base_dir_ += fpath;
		base_dir_ = PathUtil.path_Add_Slash(base_dir_);
		//trace("**** base dir='" + base_dir_ + "'");
	}

	public function add_File(key: String, fname: String): Void
	{
		if (file_map_.exists(key))
		{
			var prev: FileInfo = file_map_.get(key);
			if (prev.filename_ != fname)
			{
				trace("WARNING: add_File conflict: " + key + ":" + fname + " vs " + prev.key_ + ":" + prev.filename_);
			}
			return;
		}
		var fi: FileInfo = new FileInfo(key, fname, base_dir_);
		file_list_.push(fi);
		file_map_.set(key, fi);
	}

	public function watch(): Void
	{
		if (null == timer_)
		{
			timer_ = new Timer(elapse_ms_);
			timer_.run = on_Timer;
		}
	}

	public function trigger(): Void
	{
		for (fi in file_list_)
		{
			signal_changed_.fire(fi.key_, fi.filepath_);
		}
	}

	function on_Timer(): Void
	{
		for (fi in file_list_)
		{
			if (check_File(fi))
			{
				//trace("******* file changed " + fi.key_  + " at " + Timer.stamp());
				signal_changed_.fire(fi.key_, fi.filepath_);
			}
		}
	}

	function check_File(fi: FileInfo): Bool
	{
		var exists: Bool = fi.exists_;
		var time: Float = fi.last_modified_time_;
		fi.update();
		if (exists != fi.exists_)
			return true;
		if (exists && (time != fi.last_modified_time_))
			return true;
		return false;
	}

}

#end