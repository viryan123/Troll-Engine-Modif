package;
import lime.system.System;
import haxe.io.Path;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.io.FileOutput;
import flixel.ui.FlxBar;
import openfl.net.URLRequest;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import sys.FileSystem;
import openfl.net.URLLoader;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import Github.Release;

using StringTools;

typedef DownloadData = {
    var fileName:String;
	var fileSize:Int;
    var link:String;
}

typedef FileData = {
    var fileName:String;
    var path:String;
}

typedef DLProgress = {
	var bytesFinished:Float;
	var bytesTotal:Float;
    var files:Array<DownloadData>;
	var downloadedFiles:Array<FileData>;
	var finishedFiles:Array<FileData>;
    var currentFile:Int;
    var totalFiles:Int;
    var done:Bool;
}

class UpdaterState extends MusicBeatState {
    var release:Release;
    var downloading:Bool = false;
    var stream:URLLoader;
    var prog:DLProgress = {
        bytesFinished: 0,
        bytesTotal: 0,
        files: [],
        downloadedFiles: [],
        finishedFiles: [],
        currentFile: 0,
        totalFiles: 0,
        done: false
    }

    var path = '${Sys.getEnv("TEMP")}\\TrollEngineUpdate';
    
    public function new(r:Release){
        super();
        release=r;
    }

    var updateText:FlxText;

    var fileBar:FlxBar;
    override function create(){
		var beta = release.prerelease ? " (PRE-RELEASE)" : "";
		var currentBeta = MainMenuState.beta ? " (PRE-RELEASE)" : "";
		updateText = new FlxText(0, 0, FlxG.width,
			'You are on Troll Engine ${MainMenuState.displayedVersion}${currentBeta}, but the most recent is v${release.tag_name}${beta}!\nY = Update, N = Remind me later, I = Skip this update');
		updateText.screenCenter(Y);
		updateText.setFormat(Paths.font("calibrib.ttf"), 32, FlxColor.WHITE, CENTER);
		add(updateText);

		fileBar = new FlxBar(0, 0, LEFT_TO_RIGHT, Std.int(FlxG.width/2), 10, null, null, 0, 100, false);
		fileBar.screenCenter(XY);
		fileBar.numDivisions = 200;
		fileBar.y += 100;
		fileBar.createFilledBar(FlxColor.GRAY, FlxColor.GREEN);
        fileBar.visible = false;
		add(fileBar);
        super.create();
    }

    function installShit(){
        prog.currentFile = 0;
        prog.totalFiles = prog.downloadedFiles.length;
        prog.bytesFinished = 0;
		prog.bytesTotal = 0;
		fileBar.setRange(0, prog.totalFiles);
		updateText.text = 'Extracting (0 / ${prog.totalFiles})';

        
        var extractionPath = '${path}\\Finished';
		clearFiles(extractionPath);
		FileSystem.createDirectory(extractionPath);
        for(file in prog.downloadedFiles){
            prog.currentFile++;
            fileBar.value = prog.currentFile;
            updateText.text = 'Extracting (${prog.currentFile} / ${prog.totalFiles})';
            if(file.fileName.endsWith(".zip")){
                var toRead = File.read(file.path);
				var entries = haxe.zip.Reader.readZip(toRead);
				toRead.close();
				var extractedFiles:Int = 0;
				var totalFiles:Int = entries.length;
				updateText.text = 'Extracting (${extractedFiles} / ${totalFiles}) (${prog.currentFile} / ${prog.totalFiles})';

                for(zippedFile in entries){
					extractedFiles++;
					updateText.text = 'Extracting (${extractedFiles} / ${totalFiles}) (${prog.currentFile} / ${prog.totalFiles})';
                    var name = zippedFile.fileName;
                    trace(name);
					var fullPath = Path.join([extractionPath, name]);
                    if(name.endsWith("/")){
                        // dir
						if (!FileSystem.exists(fullPath))
							FileSystem.createDirectory(fullPath);
                        else
							clearFiles(fullPath);
                    }else{
						var directory = [for (w in name.split("/")) w.trim()];
                        directory.pop();
						FileSystem.createDirectory(Path.join([extractionPath, directory.join("/")]));
						var data = haxe.zip.Reader.unzip(zippedFile);
						File.saveBytes(fullPath, data);
                    }
                }
            }else{
                prog.finishedFiles.push(file);
            }
        }

		
    }

    function clearFiles(path:String){
		if (FileSystem.exists(path))
		{
			for (file in FileSystem.readDirectory(path))
			{
				var fp = Path.join([path, file]);
				if (FileSystem.isDirectory(fp)){
					clearFiles(fp);
                    FileSystem.deleteDirectory(fp);
                }else
					FileSystem.deleteFile(fp);
			}
		}
    }

    function startDownload(){
        downloading = true;
        FlxG.autoPause = false;
		updateText.text = "Preparing";
        // setup folder to download to

		clearFiles(path);
		FileSystem.createDirectory(path);
		
        // get every asset. there should probably only be 1 but y'know!!

		updateText.text = "Gathering files";
		prog.files = [];
        for(asset in release.assets){
			prog.files.push({
                fileName: asset.name,
                link: asset.browser_download_url,
				fileSize: asset.size
            });
			prog.totalFiles++;
        }

		updateText.text = "Starting download";
		fileBar.visible = true;

		download(function(){
            fileBar.visible = false;
            updateText.text = "Finished downloading! Preparing extraction";
	 		sys.thread.Thread.create(() ->
			{ 
                installShit();
				updateText.text = "Finished extraction! Installing to the game folder..";
				var finishedFolder = '${path}\\Finished';
                var progPath = Sys.programPath();
                var folderArray = progPath.split("\\");
				var exe = Path.withoutDirectory(folderArray.pop());
				var folder = folderArray.join("/");
				copy(finishedFolder, '', FileSystem.absolutePath(folder));
				updateText.text = "Done copying!";
 				var nu = '${Path.withoutExtension(progPath)}.tempcopy';
                FileSystem.rename(progPath, nu);
				File.copy('${finishedFolder}\\${exe}', progPath);
				prog.done = true; 
				Sys.command('start /B ${exe}');
				clearFiles(path);
                System.exit(0);
			});
        });
    }

    function copy(base:String, dir:String, dest:String){
        trace("copying from " + Path.join([base, dir]));
		for (file in FileSystem.readDirectory(Path.join([base, dir])))
		{
			var finFile = Path.join([base, dir, file]);
			var myFile = Path.join([dest, dir, file]);
			if (file.endsWith(".dll") || file.endsWith(".ndll"))
			{
				var temp = '${Path.withoutExtension(myFile)}.tempcopy';
                if(FileSystem.exists(temp))
                    FileSystem.deleteFile(temp);
				FileSystem.rename(myFile, temp); // anything with the .temp ext will be removed after the game restarts
			}
			if (file == Path.withoutDirectory(Sys.programPath()))
			{
				trace("Ignoring copying the executable");
				continue;
			}
			if (FileSystem.isDirectory(finFile)){
				if (FileSystem.exists(myFile) && !FileSystem.isDirectory(myFile)){
                    FileSystem.deleteFile(myFile);
                    trace("deletin da file " + myFile);
                }
				if (!FileSystem.exists(myFile)){
                    trace("makin da directory " + myFile);
					FileSystem.createDirectory(myFile);
                }
                
				copy(base, Path.join([dir, file]), dest);
            }else{
                trace('Copying $finFile to $myFile');
				File.copy(finFile, myFile); 
            }
            
		}
    }

    function download(onFinish:Void->Void){
		var file = prog.files.shift();
        if(file==null){
            onFinish();
            return;
        }
        prog.currentFile++;
		updateText.text = 'Starting to download ${file.fileName} (${prog.currentFile} / ${prog.totalFiles})';
		// wanted to use a while loop to download everything, but can't cus of it being async so L
		downloadFile(file, download.bind(onFinish));
    }

    function downloadFile(file:DownloadData, onFinish:Void->Void){      
		prog.bytesTotal = 1; // so no 0 / 0 bullshit
        prog.bytesFinished = 0; 
		fileBar.setRange(0, file.fileSize);
        stream = new URLLoader();
        stream.dataFormat = BINARY;
        stream.addEventListener(ProgressEvent.PROGRESS, function(e:ProgressEvent){
			prog.bytesFinished = e.bytesLoaded;
			prog.bytesTotal = e.bytesTotal;

			fileBar.setRange(0, prog.bytesTotal);
			fileBar.value = prog.bytesFinished;
            
			updateText.text = 'Downloading ${file.fileName} (${prog.bytesFinished} / ${prog.bytesTotal}) (${prog.currentFile} / ${prog.totalFiles})';
            // TODO: format the bytes downloaded and total into more readable things (KB, MB, etc)
        });
        stream.addEventListener(Event.COMPLETE, function(e:Event) {
			fileBar.percent = 100;
			prog.bytesFinished = prog.bytesTotal;
			var path = '$path\\${file.fileName}';
            var output:FileOutput = File.write(path);
            try{
                var writingData:ByteArray = new ByteArray();
                var downloadedData:ByteArray = stream.data;
                downloadedData.readBytes(writingData); // should read all bytes? if needed i'll stream it into the file output instead tho
                output.write(writingData); // should write all bytes? same as above if needed ill stream it
                prog.downloadedFiles.push({
                    fileName: file.fileName,
                    path: path
                });
            }catch(e:Dynamic){
                trace(file.fileName + " failed to write, RIP!! " + e);
            }
            output.flush();
            output.close();
			onFinish();
        });

        stream.load(new URLRequest(file.link));
    }

    var done:Bool = false;

    override function update(elapsed:Float){
        super.update(elapsed);
        
		if (downloading)return;
        if(FlxG.keys.justPressed.N){
			MusicBeatState.switchState(new TitleState());
        }else if(FlxG.keys.justPressed.I){
			Main.outOfDate = false;
			MusicBeatState.switchState(new TitleState());
			if (FlxG.save.data.ignoredUpdates == null)
				FlxG.save.data.ignoredUpdates = [];
			
			FlxG.save.data.ignoredUpdates.push(release.tag_name);
            FlxG.save.flush();
        }else if(FlxG.keys.justPressed.Y){
            startDownload();
        }

    }
}