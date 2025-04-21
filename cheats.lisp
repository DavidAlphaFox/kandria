(in-package #:org.shirakumo.fraf.kandria)

(defvar *cheat-codes* ())

(defstruct (cheat (:constructor make-cheat (name code effect)))
  (name NIL :type symbol)
  (idx 0 :type (unsigned-byte 8))
  (code "" :type simple-base-string)
  (effect NIL :type function))

(defun cheat (name)
  (find name *cheat-codes* :key #'cheat-name))

(defun (setf cheat) (cheat name)
  (let ((cheats (remove name *cheat-codes* :key #'cheat-name)))
    (setf *cheat-codes* (if cheat (list* cheat cheats) cheats))
    cheat))

(defmacro define-cheat (code &body action)
  (destructuring-bind (name code) (enlist code code)
    `(setf (cheat ',name) (make-cheat ',name
                                      ,(string-downcase code)
                                      (lambda () ,@action)))))

(defun process-cheats (key)
  (when (region +world+)
    (loop for cheat in *cheat-codes*
          for i = (cheat-idx cheat)
          for code = (cheat-code cheat)
          do (let ((new (if (string= key code :start2 i :end2 (+ i (length key))) (1+ i) 0)))
               (cond ((<= (length code) new)
                      (setf (cheat-idx cheat) 0)
                      (hide-panel 'cheat-panel)
                      (v:info :kandria.cheats "Activating cheat code ~s" (cheat-name cheat))
                      (let ((name (language-string (symb T 'cheat/ (cheat-name cheat)))))
                        (if (funcall (cheat-effect cheat))
                            (status (@formats 'game-cheat-activated name))
                            (status (@formats 'game-cheat-deactivated name)))))
                     (T
                      (setf (cheat-idx cheat) new)))))))

(define-cheat hello
  T)

(define-cheat (cheat-console cheater)
  (show-panel 'cheat-panel)
  T)

(define-cheat tpose
  (clear-retained)
  (start-animation 't-pose (node 'player T)))

(define-cheat god
  (setf (invincible-p (node 'player T)) (not (invincible-p (node 'player T)))))

(define-cheat armageddon
  (cond ((= 1 +health-multiplier+)
         (for:for ((entity over (region +world+)))
           (when (typep entity 'enemy)
             (setf (health entity) 1)))
         (setf +health-multiplier+ 0f0))
        (T
         (setf +health-multiplier+ 1f0)
         NIL)))

(define-cheat campfire
  (cond ((<= (clock-scale +world+) 60)
         (setf (clock-scale +world+) (* 60 30)))
        (T
         (setf (clock-scale +world+) 60)
         NIL)))

(define-cheat matrix
  (cond ((<= 0.9 (time-scale +world+))
         (setf (time-scale +world+) 0.1))
        (T
         (setf (time-scale +world+) 1.0)
         NIL)))

(define-cheat (i-cant-see |i can't see|)
  (setf (hour +world+) 12))

(define-cheat test
  (let ((room (node 'debug T)))
    (when room
      (place-on-ground (node 'player T) (location room))
      (setf (intended-zoom (camera +world+)) 1.0)
      (snap-to-target (camera +world+) (node 'player T)))))

(define-cheat self-destruct
  (cond ((<= (health (node 'player T)) 1)
         (setf (health (node 'player T)) 0)
         (kill (node 'player T)))
        (T
         (trigger 'explosion (node 'player T))
         (setf (health (node 'player T)) 1))))

#-kandria-demo
(flet ((noclip ()
         (setf (state (node 'player T))
               (case (state (node 'player T))
                 (:noclip :normal)
                 (T :noclip)))
         (eql (state (node 'player T)) :noclip)))
  (define-cheat noclip
    (noclip))

  (define-cheat SPISPOPD
    (noclip)))

(define-cheat nanomachines
  (setf (health (node 'player T)) (maximum-health (node 'player T))))

(define-cheat (you-must-die |you must die|)
  (kill (node 'player T)))

#-nx
(define-cheat (lp0-on-fire |lp0 on fire|)
  (error "Simulating an uncaught error."))

#-nx
(define-cheat (lp1-on-fire |lp1 on fire|)
  (error 'gl:opengl-error :error-code :out-of-memory))

#-nx
(define-cheat (lp2-on-fire |lp2 on fire|)
  (error 'gl:opengl-error :error-code :invalid-operation))

(define-cheat blingee
  (dolist (class (list-leaf-classes 'value-item) T)
    (store (class-name class) (node 'player T))))

(define-cheat motherlode
  (store 'item:parts (node 'player T) 10000))

(define-cheat (unlock-palettes |clothes make the woman|)
  (dolist (class (list-leaf-classes 'palette-unlock) T)
    (store (class-name class) (node 'player T))))

#-kandria-release
(define-cheat snapshot
  (let ((state (or (state +main+) (first (list-saves)))))
    (when state
      (submit-trace state))))

#-(or kandria-demo nx)
(define-cheat (developer |i am a developer|)
  (setf (setting :debugging :show-debug-settings) T))

(define-cheat (reveal-map |i can see forever|)
  (for:for ((unit over (region +world+)))
    (when (typep unit 'chunk)
      (setf (unlocked-p unit) T)))
  (let ((player (node 'player T)))
    (setf (stats-chunks-uncovered (stats player)) (stats-chunks-total (stats player)))))

#-kandria-demo
(define-cheat (unlock-fast-travel |lots and lots of trains|)
  (for:for ((unit over (region +world+)))
    (when (typep unit 'station)
      (setf (unlocked-p unit) T))))

(define-cheat (unlock-achievements |overachiever|)
  (mapc #'award (list-achievements)))

(define-cheat (relock-achievements |underachiever|)
  (dolist (achievement (list-achievements) T)
    (setf (active-p achievement) NIL)))

(define-cheat (show-solids |show solid tiles|)
  (let (mode)
    (for:for ((unit over (region +world+)))
      (when (typep unit 'chunk)
        (unless mode
          (setf mode (if (show-solids unit) :off :on)))
        (case mode
          (:off (setf (show-solids unit) NIL))
          (:on (setf (show-solids unit) T)))))
    (case mode
      (:off NIL)
      (:on T))))

(define-cheat (level-up |i'm feeling stronger|)
  (incf (level (node 'player T))))

(define-cheat (splits-panel |gotta go fast|)
  (toggle-panel 'splits))

(define-cheat (complete-quests |i implore you to reconsider|)
  (dolist (quest (remove-if-not #'quest:active-p (quest:known-quests (storyline +world+))) T)
    (quest:complete quest)))

(define-cheat (race-panel |how fast am i|)
  (toggle-panel 'race-results-screen))
