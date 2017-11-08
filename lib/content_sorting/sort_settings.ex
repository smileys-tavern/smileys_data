defmodule SmileysData.ContentSorting.SortSettings do
	@moduledoc """
		Hours to include in each category of sorting where terminator indicates the hour at which termination
		functionality will be called
	"""
	defstruct time_window_new: {2, 4}, time_window_medium: {4, 8}, time_window_long: {8, 12}, time_window_terminator: {71, 72}, frequency_new: "*/20 * * * *", frequency_medium: "*/30 * * * *", frequency_long: "@hourly", frequency_terminator: "@hourly", depletion_ratio_new: 0.05, depletion_ratio_medium: 0.1, depletion_ratio_long: 0.3, depletion_ratio_terminator: 0.000001
end