import Gio from "gi://Gio"

export function runCommand(command: string[], callback?: (stdout: string) => void) {
    try {
        const process = Gio.Subprocess.new(
            command,
            Gio.SubprocessFlags.STDOUT_PIPE |
            Gio.SubprocessFlags.STDERR_SILENCE,
        )

        process.communicate_utf8_async(null, null, (_process, result) => {
            try {
                const [, stdout] = process.communicate_utf8_finish(result)
                callback?.(stdout ?? "")
            } catch (error) {
                console.error(`Failed to run command: ${command.join(" ")}`, error)
            }
        })
    } catch (error) {
        console.error(`Failed to spawn command: ${command.join(" ")}`, error)
    }
}