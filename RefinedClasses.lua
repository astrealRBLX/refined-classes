--[[

	Refined Classes by AstrealDev
	
	Replication of OOP in Lua made simple.
	
	Full documentation can be found here: https://github.com/impRBLX/refined-classes

]]--



-----// Private Variables //-----
local ClassModule = {};
local Class = {};
local ClassObject = {};
local Classes = {};

-----// Private Functions //-----
local function CreateInterface(object, limitIndexing, limitSetting, nonEditableKeys, customMethods, superClassExists)
	local finalObjectTable = {};
	
	local function indexingFunction(_, key)
		if superClassExists and key == "super" then
			return ClassModule.GetClass(object.className);
		end
		for methodKey, methodValue in pairs(object.methods or {}) do
			if methodKey == key then
				return methodValue;
			end
		end
		return object[key];
	end
	
	local function settingFunction(_, key, value)
		if nonEditableKeys ~= nil then
			local isEditable = true;
			for _, val in ipairs(nonEditableKeys) do
				if key == val then
					isEditable = false;
					break;
				end
			end
			assert(isEditable, "Property '" .. tostring(key) .. "' is not directly editable.");
		else
			assert(not object[key] or key == "Initialize" or typeof(value) == "function", "Property '" .. tostring(key) .. "' is not directly editable.");
			if typeof(value) == "function" and object.methods then
				object.methods[key] = value;
				return;
			end
		end
		object[key] = value;
	end
	
	for key, value in pairs(customMethods or {}) do
		finalObjectTable[key] = value;
	end
	
	if limitIndexing then
		finalObjectTable.__index = indexingFunction;
	end
	
	if limitSetting then
		finalObjectTable.__newindex = settingFunction;
	end
	
	return finalObjectTable;
end

-----// Class Module Metamethods //-----
ClassModule.__index = ClassModule;

-----// Class Module Constructor //------
ClassModule.__call = function(cm, className, default, ...)
	local args = {...};
	
	--// Properties //--
	local self = {};
	self.name = tostring(className or "NewClass");
	self.attributes = {};
	self.methods = {};
	self.extensions = {};
	self.instances = {};
	self.Initialize = function() end
	
	for key, value in pairs(default or {}) do
		if typeof(value) == "function" then
			self.methods[key] = value;
		end
		self.attributes[key] = value;
	end
	
	for key, value in pairs(Class) do
		self[key] = value;
	end
	
	--// Interface Creation //--
	local classObjectInterface = CreateInterface(self, true, true, nil, {__call = cm.new});
	classObjectInterface = setmetatable({}, classObjectInterface);
	
	Classes[className or "NewClass"] = classObjectInterface;
	
	return classObjectInterface;
end

-----// Class Object Constructor //-----
function ClassModule.new(self, defaultMeta, ...)
	assert(self, "Creating a new class object requires that 'new' be called as a method.");
	
	--// Inherited Class Attributes //--
	local classInherited = {};
	classInherited.className = self.name;
	
	for key, value in pairs(self.attributes) do
		classInherited[key] = value;
	end
	
	for key, value in pairs(self.methods) do
		classInherited[key] = value;
	end
	
	--// Built-In Functions //--
	for key, value in pairs(ClassObject) do
		classInherited[key] = value;
	end
	
	--// Defined Constructor //--
	if self.Initialize then
		if typeof(self.Initialize) == "function" then self.Initialize(classInherited, ...) end
	end
	
	--// Interface Creation //--
	local newObj = setmetatable({}, CreateInterface(classInherited, true, true, {"className", "super", "UpdateMeta", "InstanceOf"}, defaultMeta, true));
	
	table.insert(self.instances, newObj);
	
	return newObj;
end

-----// Class Functions //-----
function Class.Extends(self, extension, default)
	assert(extension, "An extension class must provided as either a string or class.");
	if typeof(extension) ~= "table" and typeof(extension) ~= "string" then
		error("An extension class must be provided as either a string or class.");
	end
	
	if typeof(extension) == "string" then
		extension = ClassModule.GetClass(extension);
		assert(extension, "Provided class does not exist.");
	else
		assert(extension.name, "Provided class does not exist.");
		extension = ClassModule.GetClass(extension.name);
		assert(extension, "Provided class does not exist.");
	end
	
	for key, value in pairs(extension.attributes) do
		self.attributes[key] = value;
	end
	
	for key, value in pairs(default or {}) do
		if typeof(value) == "function" then
			self.methods[key] = value;
			continue
		end
		self.attributes[key] = value;
	end
	
	for key, value in pairs(extension.methods) do
		self.methods[key] = value;
	end
	
	table.insert(self.extensions, extension);
	
	return self;
end

function Class.SubClassOf(self, providedClass)
	assert(self or providedClass, "A class must be provided to use 'ClassOf'");
	
	if self == providedClass then return true end
	
	for _, extension in pairs(self.extensions) do
		if extension == providedClass then return true end
	end
	
	return false;
end

function Class.Using(self, mixin)
	assert(self or mixin, "A class and mixin must be provided to use 'Using'");
	assert(typeof(mixin) == "table", "Provided mixin must be of type table.");

	for key, value in pairs(mixin) do
		self[key] = value;
	end
end

function Class.Uses(self, mixin)
	assert(self or mixin, "A class and mixin must be provided to use 'Uses'");
	assert(typeof(mixin) == "table", "Provided mixin must be of type table.");
	
	local mixinSize = #mixin;
	local foundSize = 0;
	
	for key, value in pairs(mixin) do
		print(key, self[key])
		if self[key] then
			foundSize += 1;
		end
	end
	
	if foundSize >= mixinSize then return true end
	
	return false;
end

-----// Class Object Functions //-----
function ClassObject.UpdateMeta(self, newInt)
	assert(self, "A class object must be provided to update its interface.");
	
	local meta = getmetatable(self);
	
	assert(meta, "'UpdateMeta' cannot be called from the constructor.");
	
	for key, value in pairs(newInt) do
		assert(key ~= "__index", "Index metamethod cannot be updated.")
		assert(key ~= "__newindex", "Newindex metamethod cannot be updated.");
		meta[key] = value;
	end
	
	return setmetatable(self, meta);
end

function ClassObject.InstanceOf(self, instanceClass)
	assert(self or instanceClass, "A class must be provided to use 'InstanceOf'");
	
	if self.super == instanceClass then return true end
	
	for _, extension in pairs(self.super.extensions) do
		if extension == instanceClass then return true end
	end
	
	return false;
end

-----// Class Module Functions //-----
function ClassModule.GetClass(className)
	assert(className, "A class name must be provided to get its class.");
	
	return Classes[className];
end

return setmetatable({}, ClassModule);
