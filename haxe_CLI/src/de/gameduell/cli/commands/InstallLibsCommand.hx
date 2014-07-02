package de.gameduell.cli.commands;
/**
 * @autor kgar
 * @date 30.06.2014.
 * @company Gamduell GmbH
 */
import sys.io.Process;
import Sys;
import sys.FileSystem;
import sys.io.File;
import sys.io.File;
import haxe.Json;
import haxe.io.Error;
import de.gameduell.cli.commands.impl.IGDCommand;
class InstallLibsCommand implements IGDCommand {

    public function new() {}

    public function execute(cmd:String):String
    {
        var fileName = null;
        if (Sys.args().length > 1)
        {
            fileName = Sys.args()[1];
        }

        if (fileName == null || fileName.length == 0)//file name specified
            return "syntax error you should specifiy the file name example c:/developer/config.json";

        if (!FileSystem.exists(fileName))// File does not existe
            return "file with path '" + fileName + "' not found";

        return doInstallLibs(fileName);
    }

    public function doInstallLibs(fileName:String):String
    {
        var content:String;
        var globalErrorOccured:Bool = false;
        var repoErrorOccured:Bool = false;
        var startTime:Float = Date.now().getTime();
        var parsedContent:{version:String, dev_libs:Array<Dynamic>};
        try
        {
            Sys.println("Parsing config file Start....");
            content = File.getContent(fileName);
            parsedContent = Json.parse(content);
            Sys.println("Parsing config file Done !");
        }
        catch (e:Error)
        {
            return "Cannot Parse the file";
        }

        if (parsedContent != null && parsedContent.version != GDCommadLine.VERSION)
        {
            return "the version in the file is different then the current Version of GDShell";
        }

        for (lib in parsedContent.dev_libs) {
            Sys.println("Installing lib "+ lib.name +"===============================================");
            Sys.println("Creating directory : [" + lib.destination_path + "]");

            Sys.command("mkdir", [lib.destination_path]);

            // check git first
//            checkGit();

            //checkout into directory after creating it
            if (Sys.command("git clone \"" + lib.git_path + "\" \"" + lib.destination_path + "\"") != 0) {
                Sys.println("Could not clone git repository [" + lib.git_path + "]");
                repoErrorOccured = true;
                globalErrorOccured = true;
            }
            if(!repoErrorOccured)
            {
                var command:String = "haxelib";
                var arguments:Array<String> = ["dev",lib.name,lib.library_path];

                var process:Process = new Process(command, arguments);
                process.exitCode();

                Sys.println("Output From Haxelib : "+ process.stdout.readAll().toString());
            }
            repoErrorOccured = false;
            Sys.println("Done Installing lib "+ lib.name +"==========================================");
        }

        return "Installing done "+(globalErrorOccured ? " With some Erros" : " Without Errors");
    }

    function checkGit() {
        var gitExists = function()
        try { Sys.command("git", []); return true; } catch (e:Dynamic) return false;
        if (gitExists())
            return;
        // if we have already msys git/cmd in our PATH
        var match = ~/(.*)git([\\|\/])cmd$/ ;
        for (path in Sys.getEnv("PATH").split(";"))
        {
            if (match.match(path.toLowerCase()))
            {
                var newPath = match.matched(1) + "git" + match.matched(2) + "bin";
                Sys.putEnv("PATH", Sys.getEnv("PATH") + ";" + newPath);
            }
        }
        if (gitExists())
            return;
        // look at a few default paths
        for (path in ["C:\\Program Files (x86)\\Git\\bin", "C:\\Progra~1\\Git\\bin"])
            if (FileSystem.exists(path))
            {
                Sys.putEnv("PATH", Sys.getEnv("PATH") + ";" + path);
                if (gitExists())
                    return;
            }
        Sys.print("Could not execute git, please make sure it is installed and available in your PATH.");
    }
}
