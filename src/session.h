#ifndef AMSHELL_SESSION_H
#define AMSHELL_SESSION_H

int amshell_session_should_exit(const char *line);
long amshell_session_execute(const char *line);

#endif
