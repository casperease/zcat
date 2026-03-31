// C# process runner for Invoke-CliCommand -Mode Stream.
// Reads stdout/stderr on background threads, writes to Console.Write
// (preserves \r for spinners and ANSI escapes for colors).
// Captures output into StringBuilders for structured result.
//
// Loaded once per session by Invoke-CliCommandStreamed via Add-Type.

using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

namespace Zcap
{
    public class CliRunner
    {
        public string Stdout { get; private set; }
        public string Stderr { get; private set; }
        public int ExitCode { get; private set; }

        public static CliRunner Run(string fileName, string arguments, bool silent)
        {
            var runner = new CliRunner();
            var stdoutSb = new StringBuilder();
            var stderrSb = new StringBuilder();

            var psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            // Set Console.OutputEncoding to UTF-8 so Console.Write renders
            // Unicode characters (progress bars █) correctly. This also sets
            // the console codepage to 65001. Don't set StandardOutputEncoding
            // on PSI — that would change how .NET decodes the stream and can
            // strip ANSI escape sequences.
            var previousEncoding = Console.OutputEncoding;

            try
            {
                if (!silent) Console.OutputEncoding = Encoding.UTF8;

                using (var process = new Process { StartInfo = psi })
                {
                    process.Start();

                    // Read both streams char-by-char on background threads.
                    // Console.Write (not WriteLine) preserves \r carriage
                    // returns and passes ANSI escapes through for colors.
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
    }
}
