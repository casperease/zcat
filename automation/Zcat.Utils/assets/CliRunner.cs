// C# process runner for Invoke-Executable (Stream mode).
// Parses command strings, runs executables directly via CreateProcess/fork+exec
// (no shell). Reads stdout/stderr char-by-char on background threads, writes to Console.Write.
//
// Loaded once per session by Invoke-ExecutableStreamed via Add-Type.

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

namespace Zcat
{
    public class CliRunner
    {
        public string Stdout { get; private set; }
        public string Stderr { get; private set; }
        public int ExitCode { get; private set; }

        /// <summary>
        /// Runs a command string. Parses it into executable + arguments and runs
        /// directly (no shell). Throws if shell operators (|, &amp;&amp;, ||, ;) are detected.
        /// </summary>
        public static CliRunner Run(string commandLine, bool silent, string workingDirectory = null)
        {
            var parsed = ParseCommand(commandLine);

            if (parsed.HasShellOperator)
            {
                throw new InvalidOperationException(
                    $"Invoke-Executable runs a single command — shell operators ({parsed.ShellOperator}) are not supported. " +
                    "Break the command into separate Invoke-Executable calls, or use -Direct for shell expressions.");
            }

            return RunDirect(parsed.Executable, parsed.Arguments, silent, workingDirectory);
        }

        private static CliRunner RunDirect(string executable, List<string> arguments, bool silent, string workingDirectory)
        {
            var runner = new CliRunner();
            var stdoutSb = new StringBuilder();
            var stderrSb = new StringBuilder();

            // Resolve the executable on PATH. Process.Start with UseShellExecute=false
            // doesn't resolve .cmd/.bat/.ps1 extensions — only exact filenames.
            // Tools like az, poetry, npm, pyspark are .cmd scripts on Windows.
            var resolved = ResolveExecutable(executable);

            var psi = new ProcessStartInfo
            {
                FileName = resolved,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            if (!string.IsNullOrEmpty(workingDirectory))
            {
                psi.WorkingDirectory = workingDirectory;
            }

            // ArgumentList handles all platform-specific escaping automatically.
            foreach (var arg in arguments)
            {
                psi.ArgumentList.Add(arg);
            }

            return Execute(psi, stdoutSb, stderrSb, silent, runner);
        }

        private static CliRunner Execute(ProcessStartInfo psi, StringBuilder stdoutSb,
            StringBuilder stderrSb, bool silent, CliRunner runner)
        {
            var previousEncoding = Console.OutputEncoding;

            try
            {
                Console.OutputEncoding = Encoding.UTF8;

                using (var process = new Process { StartInfo = psi })
                {
                    process.Start();

                    var stdoutThread = new Thread(() =>
                    {
                        int ch;
                        while ((ch = process.StandardOutput.Read()) != -1)
                        {
                            char c = (char)ch;
                            if (!silent) Console.Write(c);
                            stdoutSb.Append(c);
                        }
                    });

                    var stderrThread = new Thread(() =>
                    {
                        int ch;
                        while ((ch = process.StandardError.Read()) != -1)
                        {
                            char c = (char)ch;
                            if (!silent) Console.Error.Write(c);
                            stderrSb.Append(c);
                        }
                    });

                    stdoutThread.Start();
                    stderrThread.Start();

                    process.WaitForExit();
                    stdoutThread.Join();
                    stderrThread.Join();

                    runner.ExitCode = process.ExitCode;
                }
            }
            finally
            {
                Console.OutputEncoding = previousEncoding;
            }

            runner.Stdout = stdoutSb.ToString();
            runner.Stderr = stderrSb.ToString();

            return runner;
        }

        // --- Executable resolution ---

        /// <summary>
        /// Resolves a command name to a full path by searching PATH with
        /// common executable extensions. On Windows, checks .exe, .cmd, .bat,
        /// .com in order (matching cmd.exe PATHEXT behavior). On Unix, checks
        /// the bare name (executables have no extension convention).
        /// Returns the original name if already a full path or not found.
        /// </summary>
        private static string ResolveExecutable(string name)
        {
            // Already a full/relative path with directory separator — use as-is
            if (name.Contains(Path.DirectorySeparatorChar) ||
                name.Contains(Path.AltDirectorySeparatorChar))
            {
                return name;
            }

            var pathDirs = (Environment.GetEnvironmentVariable("PATH") ?? "")
                .Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries);

            // Extensions to try. On Windows, match PATHEXT order. On Unix, bare name only.
            var extensions = System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform(
                System.Runtime.InteropServices.OSPlatform.Windows)
                ? new[] { ".exe", ".cmd", ".bat", ".com", "" }
                : new[] { "" };

            foreach (var dir in pathDirs)
            {
                foreach (var ext in extensions)
                {
                    var candidate = Path.Combine(dir, name + ext);
                    if (File.Exists(candidate))
                    {
                        return candidate;
                    }
                }
            }

            // Not found — return original, let Process.Start throw a clear error
            return name;
        }

        // --- Command string parser ---

        private class ParsedCommand
        {
            public string Executable;
            public List<string> Arguments = new List<string>();
            public bool HasShellOperator;
            public string ShellOperator;
        }

        /// <summary>
        /// Splits a command string into executable + arguments.
        /// Handles single and double quoted regions.
        /// Detects unquoted | && || which require shell execution.
        /// </summary>
        private static ParsedCommand ParseCommand(string commandLine)
        {
            var result = new ParsedCommand();
            var tokens = new List<string>();
            var current = new StringBuilder();
            int i = 0;
            int len = commandLine.Length;

            while (i < len)
            {
                char c = commandLine[i];

                if (c == '"')
                {
                    // Double-quoted region — read until closing quote
                    i++;
                    while (i < len && commandLine[i] != '"')
                    {
                        if (commandLine[i] == '\\' && i + 1 < len && commandLine[i + 1] == '"')
                        {
                            current.Append('"');
                            i += 2;
                        }
                        else
                        {
                            current.Append(commandLine[i]);
                            i++;
                        }
                    }
                    i++; // skip closing quote
                }
                else if (c == '\'')
                {
                    // Single-quoted region — read until closing quote (no escapes)
                    i++;
                    while (i < len && commandLine[i] != '\'')
                    {
                        current.Append(commandLine[i]);
                        i++;
                    }
                    i++; // skip closing quote
                }
                else if (c == '|')
                {
                    var op = (i + 1 < len && commandLine[i + 1] == '|') ? "||" : "|";
                    result.HasShellOperator = true;
                    result.ShellOperator = op;
                    return result;
                }
                else if (c == '&')
                {
                    var op = (i + 1 < len && commandLine[i + 1] == '&') ? "&&" : "&";
                    result.HasShellOperator = true;
                    result.ShellOperator = op;
                    return result;
                }
                else if (c == ';')
                {
                    result.HasShellOperator = true;
                    result.ShellOperator = ";";
                    return result;
                }
                else if (char.IsWhiteSpace(c))
                {
                    // Token boundary
                    if (current.Length > 0)
                    {
                        tokens.Add(current.ToString());
                        current.Clear();
                    }
                    i++;
                }
                else
                {
                    current.Append(c);
                    i++;
                }
            }

            // Flush last token
            if (current.Length > 0)
            {
                tokens.Add(current.ToString());
            }

            if (tokens.Count > 0)
            {
                result.Executable = tokens[0];
                for (int t = 1; t < tokens.Count; t++)
                {
                    result.Arguments.Add(tokens[t]);
                }
            }

            return result;
        }
    }
}
