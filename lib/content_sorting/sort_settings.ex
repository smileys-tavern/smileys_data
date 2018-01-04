defmodule SmileysData.ContentSorting.SortSettings do
	@moduledoc """
		Hours to include in each category of sorting where terminator indicates the hour at which termination
		functionality will be called
	"""
	defstruct time_window_new: {3, 4}, time_window_medium: {5, 7}, time_window_long: {11, 12}, time_window_terminator: {71, 72}, frequency_new: "20 * * * *", frequency_medium: "30 * * * *", frequency_long: "40 * * * *", frequency_terminator: "50 * * * *", depletion_ratio_new: 0.85, depletion_ratio_medium: 0.9, depletion_ratio_long: 0.3, depletion_ratio_terminator: 0.000001
end