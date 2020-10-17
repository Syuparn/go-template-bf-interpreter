# go-template-bf-interpreter

Brainf*ck interpreter written by go-template (not Golang!)

## Description

Go-template is turing-complete! From now on, your `cubectl` works as a bf interpreter!

## Requirements

- k8s construction tool (`kind` for example)
- `kubectl`

## Usage

```bash
# make k8s cluster (kind for example)
$ kind create cluster
$ kubectl get nodes
NAME                 STATUS   ROLES    AGE    VERSION
kind-control-plane   Ready    master   3m5s   v1.16.3

# create a pod, which includes bf source code in annotations
$ kubectl create -f hello.yaml
pod/bf-source-pod created
$ kubectl get pods
NAME            READY   STATUS    RESTARTS   AGE
bf-source-pod   0/1     Pending   0          12s

# run bf interpreter!
$ kubectl get pods -o go-template-file=bf-interpreter.tpl
Hello World!
```

## How it works

This interpreter uses k8s output formatted by go-template. BF source code is written in
pod manifest file (`hello.yaml` for example). The code is evaluated when cubectl refers
the pod's info and formats it by `bf-interpreter.tpl`.

## create new pods with your own bf source code

Copy `bf-source-template.yaml` and write your code in `metadata.annotations.src`.

> NOTE: Be careful of indentations! YAML is indent-sensitive.
