
function __ksOCMethodTools () {}
__ksOCMethodTools.prototype.importClass = window["__ksImportClass"];
__ksOCMethodTools.prototype.releaseObjects = function () {
	return window.control.call("__ks_releaseObjects");
};

window.OCTools = new __ksOCMethodTools;
window.OCTools.OCClass = {};

function __ksInvokeOCObject (value, k_arguments, isClass) {
	if (isClass) {
		this.className = value;
	} else {
		this.objKey = value;
	}
	this.funcName = k_arguments.callee.__ks_funcName;
	this.params = Array.prototype.slice.call(k_arguments);
}

function __ksImportClass (classString) {
  	var occlass = window.OCTools.OCClass;
  	var oc_class_obj = occlass[classString];
  	if (oc_class_obj === null || oc_class_obj === undefined) {
		var ocClass = window.control.call("__ks_importClass", classString);
		var obj = JSON.parse(ocClass);
		
		var oc_instance = obj.instance;
		function ks_oc_object (objKey) {
			this.__ks_objKey = objKey;
		};
		var instance_prototype = ks_oc_object.prototype;
		for (var i in oc_instance) {
			var item = oc_instance[i];
			function func () {
				var objKey = this.__ks_objKey;
				var value = new __ksInvokeOCObject(objKey, arguments, false);
				return __ksInvokeOCMethod(value);
			};
			func.__ks_funcName = item;
			instance_prototype[item] = func;
		}
		
		var oc_class = obj.class;
		function ks_oc_class (className, instanceMethod) {
			this.__ks_className = className;
			this.__ks_instance_method = instanceMethod;
		}
		var class_prototype = ks_oc_class.prototype;
		for (var i in oc_class) {
			var item = oc_class[i];
			function func () {
				var className = this.__ks_className;
				var value = new __ksInvokeOCObject(className, arguments, true);
				return __ksInvokeOCMethod(value);
			};
			func.__ks_funcName = item;
			class_prototype[item] = func;
		}
		oc_class_obj = new ks_oc_class(classString, ks_oc_object);
  		occlass[classString] = oc_class_obj;
 	}
  	return oc_class_obj;
}

function __ksGetMethodReturn (oc_class, objKey) {
	var oc_instance_obj;
	if (oc_class !== undefined && oc_class !== null) {
		var oc_instance = oc_class.__ks_instance_method;
		oc_instance_obj = new oc_instance(objKey);
	} else {
		oc_instance_obj = new Object;
		oc_instance_obj.__ks_objKey = objKey;
	}
	return oc_instance_obj;
}

function __ksInvokeOCMethod (value) {
	var json = JSON.stringify(value);
 	var returnString = window.control.call("__ks_invokeMethod", json);
	if (returnString !== undefined && returnString !== null){
		var returnData = JSON.parse(returnString);
		var type = returnData.type;
		switch (type){
			case 'object': {
				var tools = window.OCTools;
  				var occlass = tools.OCClass;
  				var returnClass = returnData.className;
  				var k_class = occlass[returnClass];
  				if (k_class === null || k_class === undefined) {
					k_class = tools.importClass(returnClass);
					occlass[returnClass] = k_class;
  				}
  				var returnObj = returnData.objKey;
  				var k_obj = __ksGetMethodReturn(k_class, returnObj);
    				return k_obj;
			}
			case 'other': {
				var returnObj = returnData.objKey;
  				var k_obj = __ksGetMethodReturn(null, returnObj);
    				return k_obj;
			}
			default :
				return returnData.value;
		}
  	}
}
