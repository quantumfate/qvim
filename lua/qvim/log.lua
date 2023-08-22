---@class Log
---@field levels table
---@field set_level function
---@field init function
---@field configure_notifications function
---@field add_entry function
---@field get_logger function
---@field get_path function
---@field trace function
---@field debug function
---@field info function
---@field warn function
---@field error function
local Log = {}
Log.__index = Log

local Log_mt = { __index = Log }

Log.levels = {
	TRACE = 1,
	DEBUG = 2,
	INFO = 3,
	WARN = 4,
	ERROR = 5,
}
vim.tbl_add_reverse_lookup(Log.levels)

function Log:set_level(level)
	if
		not pcall(function()
			local logger_ok, logger = pcall(function()
				return require("structlog").get_logger("qvim")
			end)
			local log_level = Log.levels[level:upper()]
			if logger_ok and logger and log_level then
				for _, pipeline in ipairs(logger.pipelines) do
					pipeline.level = log_level
				end
			end
		end)
	then
		vim.notify("structlog version too old, run `:Lazy sync`")
	end
end

function Log:setup()
	local status_ok, structlog = pcall(require, "structlog")
	if not status_ok then
		return nil
	end
	structlog.configure({
		lsp = {
			pipelines = {
				{
					level = structlog.level.INFO,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 0, stack_level = 0 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.FormatColorizer( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" },
						{
							level = structlog.formatters.FormatColorizer.color_level(),
						}
					),
					sink = structlog.sinks.Console(),
				},
				{
					level = structlog.level.ERROR,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 3 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.Format( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" }
					),
					sink = structlog.sinks.File(self:get_path("error", "lsp")),
				},
				{
					level = structlog.level.DEBUG,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 3 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.Format( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" }
					),
					sink = structlog.sinks.File(self:get_path("debug", "lsp")),
				},
				{
					level = structlog.level.TRACE,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 3 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.Format( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" }
					),
					sink = structlog.sinks.File(self:get_path("trace", "lsp")),
				},
			},
		},
		qvim = {
			pipelines = {
				{
					level = structlog.level.INFO,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 0, stack_level = 0 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.FormatColorizer( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" },
						{
							level = structlog.formatters.FormatColorizer.color_level(),
						}
					),
					sink = structlog.sinks.Console(),
				},
				{
					level = structlog.level.ERROR,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 3 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.Format( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" }
					),
					sink = structlog.sinks.File(self:get_path("error")),
				},
				{
					level = structlog.level.DEBUG,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 3 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.Format( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" }
					),
					sink = structlog.sinks.File(self:get_path("debug")),
				},
				{
					level = structlog.level.TRACE,
					processors = {
						structlog.processors.StackWriter(
							{ "line", "file" },
							{ max_parents = 3 }
						),
						structlog.processors.Timestamper("%H:%M:%S"),
					},
					formatter = structlog.formatters.Format( --
						"%s [%s] %s: %-30s",
						{ "timestamp", "level", "logger_name", "msg" }
					),
					sink = structlog.sinks.File(self:get_path("trace")),
				},
			},
		},
	})
end

---@param level integer [same as vim.log.levels]
---@param msg any
---@param event any
function Log:add_entry(level, msg, event, pipeline)
	pipeline = pipeline or "qvim"
	if
		not pcall(function()
			local logger = self:get_logger(pipeline)
			if not logger then
				return
			end
			logger:log(level, vim.inspect(msg), event)
		end)
	then
		vim.notify(msg, level, { title = pipeline })
	end
end

---Retrieves the handle of the logger object
---@param pipeline string|nil
---@return table|nil logger handle if found
function Log:get_logger(pipeline)
	pipeline = pipeline or "qvim"
	local logger_ok, logger = pcall(function()
		return require("structlog").get_logger(pipeline)
	end)
	if logger_ok and logger then
		return logger
	end
end

---Retrieves the path of the logfile
---@param variant string|nil
---@param pipeline string|nil
---@return string path of the logfile
function Log:get_path(variant, pipeline)
	variant = variant or ""
	pipeline = pipeline or "qvim"

	if pipeline == "qvim" then
		return string.format(
			"%s/%s-%s.log",
			get_qvim_log_dir(),
			"qvim",
			variant:lower()
		)
	else
		return string.format(
			"%s/%s/%s.log",
			get_qvim_log_dir(),
			pipeline,
			variant:lower()
		)
	end
end

---Add a log entry at TRACE level
---@param msg any
---@param event any
---@param pipeline string|nil
function Log:trace(msg, event, pipeline)
	Log:add_entry(self.levels.TRACE, msg, event, pipeline)
end

---Add a log entry at DEBUG level
---@param msg any
---@param event any
---@param pipeline string|nil
function Log:debug(msg, event, pipeline)
	Log:add_entry(self.levels.DEBUG, msg, event, pipeline)
end

---Add a log entry at INFO level
---@param msg any
---@param event any
---@param pipeline string|nil
function Log:info(msg, event, pipeline)
	Log:add_entry(self.levels.INFO, msg, event, pipeline)
end

---Add a log entry at WARN level
---@param msg any
---@param event any
---@param pipeline string|nil
function Log:warn(msg, event, pipeline)
	Log:add_entry(self.levels.WARN, msg, event, pipeline)
end

---Add a log entry at ERROR level
---@param msg any
---@param event any
---@param pipeline string|nil
function Log:error(msg, event, pipeline)
	Log:add_entry(self.levels.ERROR, msg, event, pipeline)
end

return setmetatable(Log, Log_mt)
