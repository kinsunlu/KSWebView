
function __ksOCMethodTools(){}
__ksOCMethodTools.prototype.importClass = window["__ksImportClass"];
__ksOCMethodTools.prototype.releaseObjects = function () {
	return window.control.call("__ks_releaseObjects");
};

window.OCTools = new __ksOCMethodTools;
window.OCTools.OCClass = {};

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
				var funcName = arguments.callee.__ks_funcName;
				var params = Array.prototype.slice.call(arguments);
				return __ksInvokeOCMethod(funcName, objKey, params, false);
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
				var funcName = arguments.callee.__ks_funcName;
				var params = Array.prototype.slice.call(arguments);
				return __ksInvokeOCMethod(funcName, className, params, true);
			};
			func.__ks_funcName = item;
			class_prototype[item] = func;
		}
		oc_class_obj = new ks_oc_class(classString, ks_oc_object);
  		occlass[classString] = oc_class_obj;
 	}
  	return oc_class_obj;
}

function __ksOCClassObject(funcName, className, params) {
	this.funcName = funcName;
	this.className = className;
	this.params = params;
}

function __ksOCInstanceObject(funcName, objKey, params) {
	this.funcName = funcName;
	this.objKey = objKey;
	this.params = params;
}

function __ksInvokeOCMethod(funcName, target, params, isClass) {
 	var obj;
 	if (isClass) {
 		obj = new __ksOCClassObject(funcName,target,params);
 	} else {
 		obj = new __ksOCInstanceObject(funcName,target,params);
 	}
 	var json = JSON.stringify(obj);
 	var returnString = window.control.call("__ks_invokeMethod", json);
 	return __ksGetReturnValue(returnString);
}

function __ksGetMethodReturn(oc_class, objKey) {
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

function __ksGetReturnValue (returnString) {
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
