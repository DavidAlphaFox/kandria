(in-package #:org.shirakumo.fraf.leaf)

(defclass v0 (version) ())

(define-decoder (vec2 v0) (data _p)
  (destructuring-bind (x y) data
    (vec2 x y)))

(define-encoder (vec2 v0) (_b _p)
  (list (vx vec2)
        (vy vec2)))

(define-decoder (vec3 v0) (data _p)
  (destructuring-bind (x y z) data
    (vec3 x y z)))

(define-encoder (vec3 v0) (_b _p)
  (list (vx vec3)
        (vy vec3)
        (vz vec3)))

(define-decoder (vec4 v0) (data _p)
  (destructuring-bind (x y z w) data
    (vec4 x y z w)))

(define-encoder (vec4 v0) (_b _p)
  (list (vx vec4)
        (vy vec4)
        (vz vec4)
        (vw vec4)))

(define-decoder (asset v0) (data _p)
  (destructuring-bind (pool name) data
    (asset pool name)))

(define-encoder (asset v0) (_b _p)
  (list (name (pool asset))
        (name asset)))

(define-decoder (resource v0) (data _p)
  (destructuring-bind (pool name &optional id) data
    (// pool name id)))

(define-encoder (resource v0) (_b _p)
  (error "Don't know how to get the asset that generated the resource."))
