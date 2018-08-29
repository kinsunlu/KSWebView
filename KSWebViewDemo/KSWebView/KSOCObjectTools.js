
function __ksOCMethodTools(){}
__ksOCMethodTools.prototype.importClass = window["__ksImportClass"];
__ksOCMethodTools.prototype.releaseObjects = function () {
	return window.control.call("__ks_releaseObjects");
};

window.OCTools = new __ksOCMethodTools;
window.OCTools.OCClass = {};

function __ksGetMethodReturn(oc_class, objKey) {
	var oc_instance_obj = {};
	if (oc_class !== undefined && oc_class !== null) {
		var oc_instance = oc_class.__ks_instance_method;
		for (var i in oc_instance) {
			var item = oc_instance[i];
			var func = function () {
				var callee = arguments.callee;
				var params = Array.prototype.slice.call(arguments);
				return __ksInvokeOCMethod(callee, params, false);
			};
			func.funcName = item;
			func.objKey = objKey;
			oc_instance_obj[item] = func;
		}
	}
	oc_instance_obj.__ks_ObjKey = objKey;
	return oc_instance_obj;
}

function __ksImportClass (classString) {
  	var occlass = window.OCTools.OCClass;
  	var oc_class_obj = occlass[classString];
  	if (oc_class_obj === null || oc_class_obj === undefined) {
		var ocClass = window.control.call("__ks_importClass", classString);
		var obj = JSON.parse(ocClass);
		var oc_class = obj.class;
	
		oc_class_obj = {};
		for (var i in oc_class) {
			var item = oc_class[i];
			var func = function () {
				var callee = arguments.callee;
				var params = Array.prototype.slice.call(arguments);
				return __ksInvokeOCMethod(callee, params, true);
			};
			func.funcName = item;
			func.className = classString;
			oc_class_obj[item] = func;
		}
		var oc_instance = obj.instance;
		oc_class_obj.__ks_instance_method = oc_instance;
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

function __ksInvokeOCMethod(callee, params, isClass) {
	for (var j in params) {
		var param = params[j];
		if (param !== null && typeof param === 'object') {
			var o_objKey = param.__ks_ObjKey;
			if (o_objKey !== undefined && o_objKey !== null) {
				params[j] = { 'objKey': o_objKey };
			}
		}
	}
	var funcName = callee.funcName;
 	var obj;
 	if (isClass) {
 		obj = new __ksOCClassObject(funcName,callee.className,params);
 	} else {
 		obj = new __ksOCInstanceObject(funcName,callee.objKey,params);
 	}
 	var json = JSON.stringify(obj);
 	var returnString = window.control.call("__ks_invokeMethod", json);
 	return __ksGetReturnValue(returnString);
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
