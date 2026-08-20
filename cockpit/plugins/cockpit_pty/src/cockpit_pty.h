#ifndef KYROON_PTY_H_
#define KYROON_PTY_H_

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#if defined(__linux__) || defined(__GLIBC__) || defined(__GNU__)
#define _GNU_SOURCE /* GNU glibc grantpt() prototypes */
#endif

#include "include/dart_api_dl.h"

typedef struct PtyOptions
{
    int rows;

    int cols;

    char *executable;

    char **arguments;

    char **environment;

    char *working_directory;

    Dart_Port stdout_port;

    Dart_Port exit_port;

    bool ackRead;

    /// Limpar os handles padrão herdados pelo filho (STARTF_USESTDHANDLES com
    /// NULL), no Windows. É decisão de QUEM CHAMA, não do processo: só o
    /// chamador sabe se o console que ele possui é um terminal de verdade
    /// (`flutter run`) ou o console técnico de um serviço com stdio
    /// redirecionado (o cockpit-server). No segundo caso o atalho é fatal — o
    /// shell enxerga stdin inválido, lê EOF e encerra na hora.
    bool clearStdHandles;

} PtyOptions;

typedef struct PtyHandle PtyHandle;

FFI_PLUGIN_EXPORT PtyHandle *pty_create(PtyOptions *options);

FFI_PLUGIN_EXPORT void pty_write(PtyHandle *handle, char *buffer, int length);

FFI_PLUGIN_EXPORT void pty_ack_read(PtyHandle *handle);

FFI_PLUGIN_EXPORT int pty_resize(PtyHandle *handle, int rows, int cols);

FFI_PLUGIN_EXPORT int pty_getpid(PtyHandle *handle);

FFI_PLUGIN_EXPORT char *pty_error(void);

#endif