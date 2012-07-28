(require 'dbus)

(setq session-manager-client-id nil)

(defun session-manager-call (method &rest args)
  (apply 'dbus-call-method
         :session
         "org.gnome.SessionManager"
         "/org/gnome/SessionManager"
         "org.gnome.SessionManager"
         method args))

(defun session-manager-client-private-call (client-id method &rest args)
  (apply 'dbus-call-method
         :session
         "org.gnome.SessionManager"
         client-id
         "org.gnome.SessionManager.ClientPrivate"
         method args))

(defun session-manager-client-private-register-signal (client-id signal-name handler)
  (dbus-register-signal
   :session
   "org.gnome.SessionManager"
   client-id
   "org.gnome.SessionManager.ClientPrivate"
   signal-name
   handler))

(defun session-manager-register-client (app-id client-startup-id)
  (session-manager-call "RegisterClient" app-id client-startup-id))


(defun session-manager-unregister-client ()
  (session-manager-call "UnregisterClient" session-manager-client-id))

(defun session-manager-end-session-response (is-ok reason)
  (session-manager-client-private-call session-manager-client-id "EndSessionResponse"
                                       is-ok reason))

(defvar session-manager-query-end-session-hook nil)
(defvar session-manager-end-session-hook nil)
(defvar session-manager-cancel-end-session-hook nil)
(defvar session-manager-stop-hook nil)


(defun session-manager-init (name)
  (interactive
   (list
    (read-string "Name: ")))
  (setq session-manager-client-id
        (session-manager-register-client "com.localvoid.EmacsManager"
                                         (concat "emacs-manager-" name)))
  (session-manager-client-private-register-signal
   session-manager-client-id "QueryEndSession"
   (lambda (flags)
     (message "QueryEndSession: %i" flags)
     (run-hooks 'session-manager-query-end-session-hook)
     (session-manager-end-session-response t "")))
  (session-manager-client-private-register-signal
   session-manager-client-id "EndSession"
   (lambda (flags)
     (message "EndSession: %i" flags)
     (run-hooks 'session-manager-end-session-hook)
     (run-hooks 'kill-emacs-hook)
     (session-manager-end-session-response t "")
     (setq kill-emacs-hook nil)
     (kill-emacs)))
  (session-manager-client-private-register-signal
   session-manager-client-id "CancelEndSession"
   (lambda ()
     (message "CancelEndSession")
     (run-hooks 'session-manager-cancel-end-session-hook)))
  (session-manager-client-private-register-signal
   session-manager-client-id "Stop"
   (lambda ()
     (message "Stop")
     (run-hooks 'session-manager-stop-hook)
     (kill-emacs))))

(provide 'session-manager)
