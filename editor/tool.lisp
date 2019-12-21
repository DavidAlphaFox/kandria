(in-package #:org.shirakumo.fraf.leaf)

(defclass tool ()
  ((editor :initarg :editor :accessor editor)
   (state :initform NIL :accessor state)))

(defgeneric label (tool))

(defmethod handle ((event event) (tool tool)))

(defmethod commit ((action action) (tool tool))
  (redo action (unit 'region T))
  (commit action (history (editor tool))))

(defmethod entity ((tool tool))
  (entity (editor tool)))

(defgeneric applicable-tools (thing)
  (:method-combination append :most-specific-last))

(defmethod applicable-tools append (thing)
  '(browser))

(defmethod applicable-tools append ((_ located-entity))
  '(freeform))

(defmethod applicable-tools append ((_ basic-light))
  '(remesh))

(defgeneric editor-class (thing))
(defgeneric default-tool (thing))

(defmethod editor-class (thing)
  'editor)

(defmethod default-tool (thing)
  NIL)
