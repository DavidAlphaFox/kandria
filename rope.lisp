(in-package #:org.shirakumo.fraf.kandria)

(define-asset (kandria rope-part) mesh
    (make-rectangle-mesh 2 8 :align :topcenter))

(define-shader-entity rope (lit-vertex-entity sized-entity interactable listener resizable ephemeral creatable visible-listener)
  ((name :initform (generate-name "ROPE"))
   (vertex-array :initform (// 'kandria 'rope-part))
   (chain :initform #() :accessor chain)
   (extended :initform T :initarg :extended :accessor extended
             :type boolean :documentation "Whether the rope is extended or not")
   (direction :initform +1 :initarg :direction :accessor direction
              :type integer :documentation "Which way the rope is facing -1 or +1"))
  (:inhibit-shaders (shader-entity :fragment-shader)))

(defmethod initialize-instance :after ((rope rope) &key (extended T))
  (setf (chain rope) (make-array (floor (vy (bsize rope)) 4)))
  (setf (extended rope) extended))

(defmethod stage :after ((rope rope) (area staging-area))
  (dolist (sound '(rope-extend rope-climb-1 rope-climb-2 rope-climb-3 rope-slide-down))
    (stage (// 'sound sound) area)))

(defmethod (setf extended) :after (state (rope rope))
  (ecase state
    ((T)
     (loop for i from 0 below (length (chain rope))
           do (setf (aref (chain rope) i) (list (vec 0 (* i -8)) (vec 0 (* i -8))))))
    ((NIL)
     (setf (aref (chain rope) 0) (list (vec 0 -6) (vec 0 0)))
     (setf (aref (chain rope) 1) (list (vec 0 0) (vec 0 0)))
     (loop for i from 2 below (length (chain rope))
           for pos = (vec (* (- (direction rope)) (- (* 8 (sin (/ i 2))) 16))
                          (min 8 (/ i 5)))
           do (setf (aref (chain rope) i) (list pos (vcopy pos)))))))

(defmethod contained-p ((vec vec4) (rope rope))
  (ecase (extended rope)
    ((T)
     (call-next-method))
    ((NIL)
     (let ((loc (location rope))
           (bsize (bsize rope)))
       (contained-p vec (vec (- (vx loc) (* (direction rope) 8))
                             (+ (vy loc) (vy bsize))
                             16 8))))))

(defmethod interactable-p ((rope rope))
  (not (extended rope)))

(defmethod interact ((rope rope) player)
  (unless (extended rope)
    (harmony:play (// 'sound 'rope-extend))
    (setf (slot-value rope 'extended) T)
    (loop for i from 0 below (length (chain rope))
          do (destructuring-bind (pos prev) (aref (chain rope) i)
               (nv+ pos (vec (* -2 (direction rope) (/ i 5)) (- 2 (/ i 20))))))))

(defmethod layer-index ((rope rope)) +base-layer+)

(defmethod nudge ((rope rope) pos strength)
  (let ((i (floor (- (+ (vy (location rope)) (vy (bsize rope))) (vy pos)) 8))
        (chain (chain rope)))
    (when (< 1 i (- (length chain) 1))
      (setf (vx (first (aref chain (1- i)))) 0)
      (setf (vx (first (aref chain i))) strength)
      (when (< strength 10)
        (setf (vy (first (aref chain i))) (* -8 i)))
      (incf (vx (first (aref chain (1+ i)))) (* (signum strength) -0.5)))))

(defmethod handle ((ev tick) (rope rope))
  (declare (optimize speed))
  (when (and (extended rope)
             (in-view-p (location rope) (bsize rope)))
    (let ((chain (chain rope))
          (g #.(vec 0 -100))
          (dt2 (expt (the single-float (dt ev)) 2)))
      (declare (type (simple-array T (*)) chain))
      (flet ((verlet (a b)
               (declare (type vec2 a b))
               (let ((x (vx a)) (y (vy a)))
                 (vsetf a
                        (+ x (* (- x (vx b)) 0.99) (* dt2 (vx g)))
                        (+ y (* (- y (vy b)) 0.99) (* dt2 (vy g))))
                 (vsetf b x y)))
             (relax (a b i)
               (declare (type vec2 a b))
               (let* ((dist (v- b a))
                      (dir (if (v/= 0 dist) (nvunit dist) (vec 0 0)))
                      (delta (- (vdistance a b) i))
                      (off (v* dir delta 0.5)))
                 (nv+ a off)
                 (nv- b off))))
        (dotimes (i 2)
          (loop for (a b) across chain
                do (verlet a b))
          (vsetf (first (aref chain 0)) 0 0)
          (dotimes (i 25)
            (loop for i from 1 below (length chain)
                  do (relax (first (aref chain (+ -1 i)))
                            (first (aref chain (+  0 i)))
                            8))))))))

(defmethod render ((rope rope) (program shader-program))
  (let ((chain (chain rope)))
    (translate-by 0 (vy (bsize rope)) 0)
    (loop for i from 0 below (1- (length chain))
          for (p1) = (aref chain i)
          for (p2) = (aref chain (1+ i))
          for d = (tv- p2 p1)
          for angle = (atan (vy d) (vx d))
          do (with-pushed-matrix ()
               (translate-by (vx p1) (vy p1) 0)
               (rotate-by 0 0 1 (+ angle (/ PI 2)))
               (call-next-method)))))

(define-class-shader (rope :fragment-shader 1)
  "out vec4 color;

void main(){
  maybe_call_next_method();
  color = vec4(0.3,0.2,0.05,1);
}")

(defmethod resize ((rope rope) width height)
  (vsetf (bsize rope) (/ +tile-size+ 2) (/ height 2))
  (setf (chain rope) (make-array (floor height 8)))
  (loop for i from 0 below (length (chain rope))
        do (setf (aref (chain rope) i) (list (vec 0 (* i -8)) (vec 0 (* i -8))))))
