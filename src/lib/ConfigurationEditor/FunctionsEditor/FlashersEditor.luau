-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../../log")
local types = require("../../../types")
local UIState = require("../../UIState")
local Fusion = require("../../../../Packages/fusion")

export type FlasherColumnState = {
	lightName: Fusion.Value<string>,
	rows: Fusion.Value<{ number }>,
}

export type FlasherSectionState = {
	waitTime: Fusion.Value<number>,
	rowCount: Fusion.Value<number>,
	columns: Fusion.Value<{ FlasherColumnState }>,
}

export type FlashersState = Fusion.Value<{ FlasherSectionState }>

local FlashersEditor = {}

local function flasherColumnToState(scope: types.Scope, column: types.flasherColumn): FlasherColumnState
	return {
		lightName = scope:Value(column.lightName),
		rows = scope:Value(table.clone(column.rows)),
	}
end

local function flasherSectionToState(scope: types.Scope, section: types.flasherSection): FlasherSectionState
	local columns = {}
	for _, column in ipairs(section.columns) do
		table.insert(columns, flasherColumnToState(scope, column))
	end

	return {
		waitTime = scope:Value(section.waitTime),
		rowCount = scope:Value(section.rowCount),
		columns = scope:Value(columns),
	}
end

function FlashersEditor.toState(scope: types.Scope, flashers: { types.flasherSection }): FlashersState
	local flasherSections = {}
	for _, section in ipairs(flashers) do
		table.insert(flasherSections, flasherSectionToState(scope, section))
	end

	return scope:Value(flasherSections)
end

function FlashersEditor.fromState(scope: types.Scope, flashersState: FlashersState): { types.flasherSection }
	local flashers: { types.flasherSection } = {}
	for _, flasherSectionState in ipairs(scope.peek(flashersState)) do
		local columns: { types.flasherColumn } = {}
		for _, columnState in ipairs(scope.peek(flasherSectionState.columns)) do
			table.insert(columns, {
				lightName = scope.peek(columnState.lightName),
				rows = table.clone(scope.peek(columnState.rows)),
			})
		end
		table.insert(flashers, {
			waitTime = scope.peek(flasherSectionState.waitTime),
			rowCount = scope.peek(flasherSectionState.rowCount),
			columns = columns,
		})
	end
	return flashers
end

function FlashersEditor.createActions(
	getContext: (functionId: number, patternIndex: number) -> (types.Scope, FlashersState)
)
	local actions = {}

	function actions.addFlasherSection(
		functionId: number,
		patternIndex: number,
		section: types.flasherSection,
		atPoint: number?
	)
		local scope, state = getContext(functionId, patternIndex)

		local flasherSections = scope.peek(state)
		table.insert(flasherSections, atPoint or #flasherSections + 1, flasherSectionToState(scope, section))
		state:set(flasherSections)
		UIState.unsavedChanges:set(true)
	end

	function actions.removeFlasherSection(functionId: number, patternIndex: number, sectionIndex: number)
		local scope, state = getContext(functionId, patternIndex)

		local flasherSections = scope.peek(state)
		table.remove(flasherSections, sectionIndex)
		state:set(flasherSections)
		UIState.unsavedChanges:set(true)
	end

	local function getFlasherSectionState(
		functionId: number,
		patternIndex: number,
		sectionIndex: number
	): FlasherSectionState
		local scope, state = getContext(functionId, patternIndex)

		local flasherSections = scope.peek(state)
		local sectionState = flasherSections[sectionIndex]
		if sectionState == nil then
			error(
				`No flasher section found at index {sectionIndex} for patternIndex {patternIndex} and functionId {functionId}`
			)
		end

		return sectionState
	end

	function actions.updateFlasherSectionWaitTime(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		newWaitTime: number
	)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		sectionState.waitTime:set(newWaitTime)
		UIState.unsavedChanges:set(true)
	end

	function actions.addSectionRow(functionId: number, patternIndex: number, sectionIndex: number)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		local currentRowCount = scope.peek(sectionState.rowCount)
		sectionState.rowCount:set(currentRowCount + 1)
		UIState.unsavedChanges:set(true)

		local columns = scope.peek(sectionState.columns)
		for _, column in ipairs(columns) do
			local rows = scope.peek(column.rows)
			table.insert(rows, 0)
			column.rows:set(rows)
			UIState.unsavedChanges:set(true)
		end
	end

	function actions.removeSectionRow(functionId: number, patternIndex: number, sectionIndex: number, rowIndex: number)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		local currentRowCount = scope.peek(sectionState.rowCount)
		if rowIndex < 1 or rowIndex > currentRowCount or rowIndex % 1 ~= 0 then
			log.warn(
				`Cannot remove invalid row {rowIndex} from section with {currentRowCount} rows for sectionIndex {sectionIndex}, patternIndex {patternIndex}, and functionId {functionId}`
			)
			return
		end
		local columns = scope.peek(sectionState.columns)
		for _, column in ipairs(columns) do
			local rows = scope.peek(column.rows)
			if rowIndex < 1 or rowIndex > #rows then
				log.warn(
					`Row index {rowIndex} is out of bounds for column with {#rows} rows in sectionIndex {sectionIndex}, patternIndex {patternIndex}, and functionId {functionId}`
				)
				return
			end
		end

		sectionState.rowCount:set(currentRowCount - 1)
		UIState.unsavedChanges:set(true)
		for _, column in ipairs(columns) do
			local rows = scope.peek(column.rows)
			table.remove(rows, rowIndex)
			column.rows:set(rows)
			UIState.unsavedChanges:set(true)
		end
	end

	function actions.addFlasherColumn(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		column: types.flasherColumn,
		atPoint: number?
	)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		local columns = scope.peek(sectionState.columns)
		table.insert(columns, atPoint or #columns + 1, flasherColumnToState(scope, column))
		sectionState.columns:set(columns)
		UIState.unsavedChanges:set(true)
	end

	function actions.removeFlasherColumn(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		columnIndex: number
	)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		local columns = scope.peek(sectionState.columns)
		table.remove(columns, columnIndex)
		sectionState.columns:set(columns)
		UIState.unsavedChanges:set(true)
	end

	function actions.updateFlasherColumnLightName(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		columnIndex: number,
		newLightName: string
	)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		local columns = scope.peek(sectionState.columns)
		local columnState = columns[columnIndex]
		if columnState == nil then
			log.warn(
				`No flasher column found at index {columnIndex} for sectionIndex {sectionIndex}, patternIndex {patternIndex}, and functionId {functionId}`
			)
			return
		end

		columnState.lightName:set(newLightName)
		UIState.unsavedChanges:set(true)
	end

	function actions.updateFlasherColumnRow(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		columnIndex: number,
		rowIndex: number,
		newRowValue: number
	)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFlasherSectionState(functionId, patternIndex, sectionIndex)

		local columns = scope.peek(sectionState.columns)
		local columnState = columns[columnIndex]
		if columnState == nil then
			log.warn(
				`No flasher column found at index {columnIndex} for sectionIndex {sectionIndex}, patternIndex {patternIndex}, and functionId {functionId}`
			)
			return
		end

		local rows = table.clone(scope.peek(columnState.rows))
		if rows[rowIndex] == nil then
			log.warn(
				`No flasher row found at index {rowIndex} for columnIndex {columnIndex}, sectionIndex {sectionIndex}, patternIndex {patternIndex}, and functionId {functionId}`
			)
			return
		end
		rows[rowIndex] = newRowValue
		columnState.rows:set(rows)
		UIState.unsavedChanges:set(true)
	end

	return actions
end

return FlashersEditor
