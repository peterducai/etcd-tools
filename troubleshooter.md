# troubleshooter



## OLM

Restart the catalog-source and catalog-operator pods.

~~~
$ oc delete pod <redhat-operators> -n openshift-marketplace
$ oc delete pod <catalog-operator> -n openshift-operator-lifecycle-manager
~~~