# Added lines by file

## apps/persia/app/domain/form.go
```diff
+ func (vs ParsedProcedureFormValues) GetValues(sectionID uuid.UUID, groupID uuid.UUID, inputID uuid.UUID) []string {
+ 	valuesInGroup, exists := vs[sectionID]
+ 	if !exists {
+ 		return []string{}
+ 	}
+ 	for _, group := range valuesInGroup {
+ 		if group.GroupID != groupID {
+ 			continue
+ 		}
+ 		values, exists := group.Values[inputID]
+ 		if !exists {
+ 			return []string{}
+ 		}
+ 		return values
+ 	}
+ 	return []string{}
+ }
+ 
+ func (vs ParsedProcedureFormValues) SetValues(sectionID uuid.UUID, groupID uuid.UUID, inputID uuid.UUID, values []string) ParsedProcedureFormValues {
+ 	valuesInGroup, exists := vs[sectionID]
+ 	if !exists {
+ 		// sectionIDが存在しない場合は新しく作成
+ 		vs[sectionID] = []ValuesInGroup{
+ 			{
+ 				GroupID:   groupID,
+ 				Values:    map[uuid.UUID][]string{inputID: values},
+ 				FileNames: map[uuid.UUID][]string{inputID: {}},
+ 			},
+ 		}
+ 		return vs
+ 	}
+ 
+ 	// 既存のgroupIDを探す
+ 	for _, group := range valuesInGroup {
+ 		if group.GroupID != groupID {
+ 			continue
+ 		}
+ 		group.Values[inputID] = values
+ 		group.FileNames[inputID] = []string{}
+ 		return vs
+ 	}
+ 
+ 	// groupIDが存在しない場合は新しく追加
+ 	newGroup := ValuesInGroup{
+ 		GroupID:   groupID,
+ 		Values:    map[uuid.UUID][]string{inputID: values},
+ 		FileNames: map[uuid.UUID][]string{inputID: {}},
+ 	}
+ 	vs[sectionID] = append(vs[sectionID], newGroup)
+ 
+ 	return vs
+ }
+ 
+ // 下のような、GroupID は割り振られているが InputID に対して値がひとつもない valuesInGroup を ParsedProcedureFormValues から取り除く
+ /*
+ 	{
+ 		"groupID": "~",
+ 		"values": {
+ 			"<InputID>": ["", ""], ← 空文字しかない
+ 			...
+ 		},
+ 	}
+ */
+ func (vs ParsedProcedureFormValues) RemoveEmptyGroupFromParsedFormValues() ParsedProcedureFormValues {
+ 	res := make(ParsedProcedureFormValues, 0)
+ 	for sectionID := range vs {
+ 		res[sectionID] = make([]ValuesInGroup, 0, len(vs[sectionID]))
+ 		for _, valuesInGroup := range vs[sectionID] {
+ 			if valuesInGroup.IsEmptyInputGroup() {
+ 				continue
+ 			}
+ 			res[sectionID] = append(res[sectionID], valuesInGroup)
+ 		}
+ 	}
+ 	return res
+ }
+ 
```

## apps/persia/app/domain/form_test.go
```diff
+ 
+ func TestParsedProcedureFormValues_GetValues(t *testing.T) {
+ 	multipleSectionID := util.NewFixedUUID("11556abe-38bf-42ec-9b84-b3b53d931f53")
+ 	singleSectionID := util.NewFixedUUID("5aff1768-c5b6-403b-a5e4-1c86c2890a06")
+ 
+ 	groupID1 := util.NewFixedUUID("6e6382df-a781-4aa4-abb7-ea4004a5de1e")
+ 	groupID2 := util.NewFixedUUID("2f1a8d67-682f-49d4-a95c-430d334a87aa")
+ 	defaultGroupID := util.NewFixedUUID(DefaultGroupID)
+ 
+ 	singleInputID1 := util.NewFixedUUID("536e2caf-3044-48b4-8d68-37d19033acd2")
+ 	singleInputID2 := util.NewFixedUUID("7584b0ec-fdf3-424b-8982-dd428be2c8b0")
+ 	multipleInputID1 := util.NewFixedUUID("02128cf8-5424-4f20-b678-964285f523e6")
+ 	multipleInputID2 := util.NewFixedUUID("6ac7548b-b84e-40bd-9d50-6820325af485")
+ 
+ 	parsedValues := ParsedProcedureFormValues{
+ 		multipleSectionID: {
+ 			{
+ 				GroupID: groupID1,
+ 				Values: map[uuid.UUID][]string{
+ 					singleInputID1: {"value in multipleSection(groupID1), singleInputID1"},
+ 					multipleInputID1: {
+ 						"value1 in multipleSection(groupID1), multipleInputID1",
+ 						"value2 in multipleSection(groupID1), multipleInputID1",
+ 					},
+ 				},
+ 			},
+ 			{
+ 				GroupID: groupID2,
+ 				Values: map[uuid.UUID][]string{
+ 					singleInputID1: {"value in multipleSection(groupID2), singleInputID1"},
+ 					multipleInputID1: {
+ 						"value1 in multipleSection(groupID2), multipleInputID1",
+ 						"value2 in multipleSection(groupID2), multipleInputID1",
+ 					},
+ 				},
+ 			},
+ 		},
+ 		singleSectionID: {
+ 			{
+ 				GroupID: defaultGroupID,
+ 				Values: map[uuid.UUID][]string{
+ 					singleInputID2: {"value in singleSection, singleInputID2"},
+ 					multipleInputID2: {
+ 						"value1 in singleSection, multipleInputID2",
+ 						"value2 in singleSection, multipleInputID2",
+ 					},
+ 				},
+ 			},
+ 		},
+ 	}
+ 	type args struct {
+ 		sectionID uuid.UUID
+ 		groupID   uuid.UUID
+ 		inputID   uuid.UUID
+ 	}
+ 	tests := []struct {
+ 		name string
+ 		vs   ParsedProcedureFormValues
+ 		args args
+ 		want []string
+ 	}{
+ 		{
+ 			name: "not found - empty values",
+ 			vs:   ParsedProcedureFormValues{},
+ 			args: args{
+ 				sectionID: singleSectionID,
+ 				groupID:   groupID1,
+ 				inputID:   singleInputID1,
+ 			},
+ 			want: []string{},
+ 		},
+ 		// multiple Section Tests(groupID1)
+ 		{
+ 			name: "found - multiple section(groupID1), single input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: multipleSectionID,
+ 				groupID:   groupID1,
+ 				inputID:   singleInputID1,
+ 			},
+ 			want: []string{"value in multipleSection(groupID1), singleInputID1"},
+ 		},
+ 		{
+ 			name: "found - multiple section(groupID1), multiple input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: multipleSectionID,
+ 				groupID:   groupID1,
+ 				inputID:   multipleInputID1,
+ 			},
+ 			want: []string{
+ 				"value1 in multipleSection(groupID1), multipleInputID1",
+ 				"value2 in multipleSection(groupID1), multipleInputID1",
+ 			},
+ 		},
+ 
+ 		// multiple Section Tests(groupID2)
+ 		{
+ 			name: "found - multiple section(groupID2), single input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: multipleSectionID,
+ 				groupID:   groupID2,
+ 				inputID:   singleInputID1,
+ 			},
+ 			want: []string{"value in multipleSection(groupID2), singleInputID1"},
+ 		},
+ 		{
+ 			name: "found - multiple section(groupID2), multiple input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: multipleSectionID,
+ 				groupID:   groupID2,
+ 				inputID:   multipleInputID1,
+ 			},
+ 			want: []string{
+ 				"value1 in multipleSection(groupID2), multipleInputID1",
+ 				"value2 in multipleSection(groupID2), multipleInputID1",
+ 			},
+ 		},
+ 
+ 		// multiple Section Tests(unknown groupID)
+ 		{
+ 			name: "not found (unknown groupID)- multiple section, single input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: multipleSectionID,
+ 				groupID:   uuid.Nil,
+ 				inputID:   singleInputID1,
+ 			},
+ 			want: []string{},
+ 		},
+ 		{
+ 			name: "not found (unknown groupID)- multiple section, multiple input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: multipleSectionID,
+ 				groupID:   uuid.Nil,
+ 				inputID:   multipleInputID1,
+ 			},
+ 			want: []string{},
+ 		},
+ 
+ 		// single Section Tests
+ 		{
+ 			name: "found - single section, single input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: singleSectionID,
+ 				groupID:   defaultGroupID,
+ 				inputID:   singleInputID2,
+ 			},
+ 			want: []string{"value in singleSection, singleInputID2"},
+ 		},
+ 		{
+ 			name: "found - single section, multiple input",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: singleSectionID,
+ 				groupID:   defaultGroupID,
+ 				inputID:   multipleInputID2,
+ 			},
+ 			want: []string{
+ 				"value1 in singleSection, multipleInputID2",
+ 				"value2 in singleSection, multipleInputID2",
+ 			},
+ 		},
+ 
+ 		// other not found cases
+ 		{
+ 			name: "not found - unknown sectionID",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: uuid.Nil,
+ 				groupID:   groupID1,
+ 				inputID:   singleInputID1,
+ 			},
+ 			want: []string{},
+ 		},
+ 		{
+ 			name: "not found - unknown inputID",
+ 			vs:   parsedValues,
+ 			args: args{
+ 				sectionID: singleSectionID,
+ 				groupID:   defaultGroupID,
+ 				inputID:   uuid.Nil,
+ 			},
+ 			want: []string{},
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got := tt.vs.GetValues(tt.args.sectionID, tt.args.groupID, tt.args.inputID)
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
+ 
+ func TestParsedProcedureFormValues_SetValues(t *testing.T) {
+ 	sectionID1 := util.NewFixedUUID("5097b9a9-2e75-48dc-9242-b190c15222b2")
+ 	groupID1 := util.NewFixedUUID("33f487e3-3d1c-40f1-aceb-f3ba3f100862")
+ 	groupID2 := util.NewFixedUUID("b20a0d8f-3a81-43a1-8c21-586c7983d99b")
+ 	inputID1 := util.NewFixedUUID("3fd4d782-415d-4729-84bf-8b82ea5d09ed")
+ 	inputID2 := util.NewFixedUUID("5992fa4c-63be-4f80-9b4d-ab8182446d44")
+ 
+ 	type args struct {
+ 		sectionID uuid.UUID
+ 		groupID   uuid.UUID
+ 		inputID   uuid.UUID
+ 		values    []string
+ 	}
+ 	tests := []struct {
+ 		name string
+ 		vs   ParsedProcedureFormValues
+ 		args args
+ 		want ParsedProcedureFormValues
+ 	}{
+ 		{
+ 			name: "create new section and group",
+ 			vs:   ParsedProcedureFormValues{},
+ 			args: args{
+ 				sectionID: sectionID1,
+ 				groupID:   groupID1,
+ 				inputID:   inputID1,
+ 				values:    []string{"value1", "value2"},
+ 			},
+ 			want: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"value1", "value2"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "add new group to existing section",
+ 			vs: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"existing_value"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			args: args{
+ 				sectionID: sectionID1,
+ 				groupID:   groupID2,
+ 				inputID:   inputID1,
+ 				values:    []string{"new_value"},
+ 			},
+ 			want: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"existing_value"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 					{
+ 						GroupID: groupID2,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"new_value"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "update existing section and group",
+ 			vs: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"old_value"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			args: args{
+ 				sectionID: sectionID1,
+ 				groupID:   groupID1,
+ 				inputID:   inputID1,
+ 				values:    []string{"updated_value1", "updated_value2"},
+ 			},
+ 			want: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"updated_value1", "updated_value2"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "add new input to existing group",
+ 			vs: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"existing_value"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			args: args{
+ 				sectionID: sectionID1,
+ 				groupID:   groupID1,
+ 				inputID:   inputID2,
+ 				values:    []string{"additional_value"},
+ 			},
+ 			want: ParsedProcedureFormValues{
+ 				sectionID1: []ValuesInGroup{
+ 					{
+ 						GroupID: groupID1,
+ 						Values: map[uuid.UUID][]string{
+ 							inputID1: {"existing_value"},
+ 							inputID2: {"additional_value"},
+ 						},
+ 						FileNames: map[uuid.UUID][]string{
+ 							inputID1: {},
+ 							inputID2: {},
+ 						},
+ 					},
+ 				},
+ 			},
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got := tt.vs.SetValues(tt.args.sectionID, tt.args.groupID, tt.args.inputID, tt.args.values)
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
```

## apps/persia/app/domain/procedure.go
```diff
+ type CSVDownloadResultType = int16
+ 
+ 	CSVDownloadSuccess CSVDownloadResultType = iota
```

## apps/persia/app/domain/procedure/proceduretemplates/test/csv_definitions_test.go
```diff
+ package test
+ 
+ import (
+ 	"testing"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/util"
+ 	"github.com/stretchr/testify/assert"
+ )
+ 
+ func Test_CSVDefinitions_ChangeStatusDocuments(t *testing.T) {
+ 	runForProcedureVersionDetail(t, func(t *testing.T, detail procedureform.ProcedureVersionDetail) {
+ 		t.Helper()
+ 		if len(detail.CSVDefinitions.Definitions) == 0 {
+ 			// CSV定義が存在しない場合はスキップ
+ 			return
+ 		}
+ 		for _, csvDef := range detail.CSVDefinitions.Definitions {
+ 			changeStatusDocuments := csvDef.ChangeStatusDocuments
+ 			// EnabledDocumentIDs と DisabledDocumentIDs に重複がないことを確認する
+ 			assert.Empty(t, util.IntersectionList(changeStatusDocuments.EnabledDocumentIDs, changeStatusDocuments.DisabledDocumentIDs))
+ 		}
+ 	})
+ }
+ 
+ func Test_CSVDefinitions_ChangeStatusPages(t *testing.T) {
+ 	runForProcedureVersionDetail(t, func(t *testing.T, detail procedureform.ProcedureVersionDetail) {
+ 		t.Helper()
+ 		if len(detail.CSVDefinitions.Definitions) == 0 {
+ 			// CSV定義が存在しない場合はスキップ
+ 			return
+ 		}
+ 		for _, csvDef := range detail.CSVDefinitions.Definitions {
+ 			for _, pages := range csvDef.ChangeStatusPages {
+ 				// PageStatusFrom の中に PageStatusTo が含まれていないことを確認する
+ 				assert.NotContains(t, pages.PageStatusFrom, pages.PageStatusTo)
+ 			}
+ 		}
+ 	})
+ }
```

## apps/persia/app/domain/procedure_v2.go
```diff
+ type CSVDownloadErrorsToSaveV2 []CSVDownloadErrorToSaveV2
+ 
+ func (es CSVDownloadErrorsToSaveV2) MergeErrorsByMemberID() CSVDownloadErrorsToSaveV2 {
+ 	byMemberIDs := make(map[MemberID][]ProcedureCSVCreationErrorLocation)
+ 	for _, e := range es {
+ 		byMemberIDs[MemberID(e.MemberID)] = append(byMemberIDs[MemberID(e.MemberID)], e.ErrorLocations...)
+ 	}
+ 
+ 	res := make(CSVDownloadErrorsToSaveV2, 0, len(byMemberIDs))
+ 	for memberID, locations := range byMemberIDs {
+ 		res = append(res, CSVDownloadErrorToSaveV2{
+ 			MemberID:       string(memberID),
+ 			ErrorLocations: locations,
+ 		})
+ 	}
+ 
+ 	return res
+ }
+ 
+ type CSVUploadResultType uint8
+ 	CSVUploadSuccess CSVUploadResultType = iota
+ 	Status        CSVUploadResultType
+ 	Status        CSVUploadResultType
```

## apps/persia/app/domain/procedurecsv/common.go
```diff
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
```

## apps/persia/app/domain/procedureform/csv_converter.go
```diff
+ package procedureform
+ 
+ import (
+ 	"time"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/times"
+ )
+ 
+ type CSVValueConverter struct {
+ 	// InputValues と　csvValue を相互に変換するための関数. この2つは関数は互いに逆の変換を行う
+ 	ToCSVValue   func(vs InputValues, input Input) (string, error)
+ 	ToInputValue func(currentValue InputValues, csvValue string, input Input) (InputValues, error)
+ }
+ 
+ // InputTypeIntegerのCSVValueConverter
+ var (
+ 	Integer_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 
+ 		formatted, err := formatToCSVValueInteger(rv)
+ 		if err != nil {
+ 			return "", perrors.AsIs(err)
+ 		}
+ 		return formatted, nil
+ 	}
+ 	Integer_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		normalized, err := normalizeCSVInputInteger(csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		v := NewInputValue(normalized)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	Integer_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   Integer_ToCSVValue,
+ 		ToInputValue: Integer_ToInputValue,
+ 	}
+ )
+ 
+ // InputTypeFloatのCSVValueConverter
+ var (
+ 	Float_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 
+ 		formatted, err := formatToCSVValueFloat(rv)
+ 		if err != nil {
+ 			return "", perrors.AsIs(err)
+ 		}
+ 		return formatted, nil
+ 	}
+ 	Float_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		normalized, err := normalizeCSVInputFloat(csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		v := NewInputValue(normalized)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	Float_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   Float_ToCSVValue,
+ 		ToInputValue: Float_ToInputValue,
+ 	}
+ )
+ 
+ // InputTypeSingleSelectionのCSVValueConverter
+ var (
+ 	SingleSelection_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 
+ 		formatted, err := formatToCSVValueSingleSelection(input, rv)
+ 		if err != nil {
+ 			return "", perrors.AsIs(err)
+ 		}
+ 		return formatted, nil
+ 	}
+ 	SingleSelection_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		normalized, err := normalizeCSVInputSingleSelection(input, csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		v := NewInputValue(normalized)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	SingleSelection_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   SingleSelection_ToCSVValue,
+ 		ToInputValue: SingleSelection_ToInputValue,
+ 	}
+ )
+ 
+ // InputTypeToggleのCSVValueConverter
+ var (
+ 	Toggle_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 
+ 		formatted, err := formatToCSVValueToggle(input, rv)
+ 		if err != nil {
+ 			return "", perrors.AsIs(err)
+ 		}
+ 		return formatted, nil
+ 	}
+ 	Toggle_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		normalized, err := normalizeCSVInputToggle(input, csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		v := NewInputValue(normalized)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	Toggle_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   Toggle_ToCSVValue,
+ 		ToInputValue: Toggle_ToInputValue,
+ 	}
+ )
+ 
+ // InputTypeLargeToggleのCSVValueConverter
+ var (
+ 	LargeToggle_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 
+ 		formatted, err := formatToCSVValueLargeToggle(input, rv)
+ 		if err != nil {
+ 			return "", perrors.AsIs(err)
+ 		}
+ 		return formatted, nil
+ 	}
+ 	LargeToggle_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		normalized, err := normalizeCSVInputLargeToggle(input, csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		v := NewInputValue(normalized)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	LargeToggle_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   LargeToggle_ToCSVValue,
+ 		ToInputValue: LargeToggle_ToInputValue,
+ 	}
+ )
+ 
+ // InputTypeDateのCSVValueConverter
+ var (
+ 	Date_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 
+ 		return rv, nil
+ 	}
+ 	Date_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		normalized, err := normalizeCSVInputDate(csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		v := NewInputValue(normalized)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	Date_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   Date_ToCSVValue,
+ 		ToInputValue: Date_ToInputValue,
+ 	}
+ )
+ 
+ // その他のInputTypeのCSVValueConverter
+ var (
+ 	DefaultType_ToCSVValue = func(vs InputValues, input Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		rv := inputValue.RawValue()
+ 		return rv, nil
+ 	}
+ 	DefaultType_ToInputValue = func(_ InputValues, csvValue string, input Input) (InputValues, error) {
+ 		v := NewInputValue(csvValue)
+ 		return InputValues{v}, nil
+ 	}
+ 
+ 	DefaultType_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   DefaultType_ToCSVValue,
+ 		ToInputValue: DefaultType_ToInputValue,
+ 	}
+ )
+ 
+ var (
+ 	DateRangeStart_ToCSVValue = func(vs InputValues, _ Input) (string, error) {
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		dr, _, convertErr := inputValue.ParseDateRange()
+ 		if convertErr != nil {
+ 			return "", perrors.Internalf("failed to convert input value to DateRange")
+ 		}
+ 		if dr.Start == nil {
+ 			return "", nil // 開始日が設定されていない場合は空文字列
+ 		}
+ 		return dr.Start.Format(time.DateOnly), nil
+ 	}
+ 	DateRangeStart_ToInputValue = func(currentValue InputValues, csvValue string, _ Input) (InputValues, error) {
+ 		// currentValue を dateRange に変換する
+ 		cv := currentValue.GetInputValueByIndex(0)
+ 		dr, _, convertErr := cv.ParseDateRange()
+ 		if convertErr != nil {
+ 			return nil, perrors.Internalf("failed to convert input value to DateRange")
+ 		}
+ 
+ 		normalized, err := normalizeCSVInputDate(csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 		if normalized != "" {
+ 			// csvValue を time.Time に変換する
+ 			timeValue, err := times.ParseToDateInJst(normalized)
+ 			if err != nil {
+ 				return nil, NewCSVUploadDataError(domain.CSVUploadDataErrorsToSaveV2{
+ 					{
+ 						ErrorType: domain.ProcedureCSVErrorTypeCannotConvertToDate,
+ 					},
+ 				})
+ 			}
+ 
+ 			// DateRange の Start に設定する
+ 			dr.Start = &timeValue
+ 		} else {
+ 			dr.Start = nil // 開始日が空文字列の場合は nil に設定する
+ 		}
+ 		// DateRange を inputValue に戻す
+ 		inputValue, err := NewInputValueFromDateRange(dr)
+ 		if err != nil {
+ 			return nil, perrors.Internalf("failed to create InputValue from DateRange: %w", err)
+ 		}
+ 
+ 		return InputValues{inputValue}, nil
+ 	}
+ 
+ 	DateRangeStart_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   DateRangeStart_ToCSVValue,
+ 		ToInputValue: DateRangeStart_ToInputValue,
+ 	}
+ )
+ 
+ var (
+ 	DateRangeEnd_ToCSVValue = func(vs InputValues, _ Input) (string, error) {
+ 		// vs から DateRange を取得する
+ 		inputValue := vs.GetInputValueByIndex(0)
+ 		dr, _, convertErr := inputValue.ParseDateRange()
+ 		if convertErr != nil {
+ 			return "", perrors.BadRequestf("failed to convert input value to DateRange")
+ 		}
+ 
+ 		// DateRange の End を文字列に変換する
+ 		if dr.End == nil {
+ 			return "", nil // 開始日が設定されていない場合は空文字列
+ 		}
+ 		return dr.End.Format(time.DateOnly), nil
+ 	}
+ 	DateRangeEnd_ToInputValue = func(currentValue InputValues, csvValue string, _ Input) (InputValues, error) {
+ 		// currentValue　を dateRange に変換する
+ 		cv := currentValue.GetInputValueByIndex(0)
+ 		dr, _, convertErr := cv.ParseDateRange()
+ 		if convertErr != nil {
+ 			return nil, perrors.Internalf("failed to convert input value to DateRange")
+ 		}
+ 
+ 		normalized, err := normalizeCSVInputDate(csvValue)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 		if normalized != "" {
+ 			// csvValue を time.Time に変換する
+ 			timeValue, err := times.ParseToDateInJst(normalized)
+ 			if err != nil {
+ 				return nil, NewCSVUploadDataError(domain.CSVUploadDataErrorsToSaveV2{
+ 					{
+ 						ErrorType: domain.ProcedureCSVErrorTypeCannotConvertToDate,
+ 					},
+ 				})
+ 			}
+ 
+ 			// DateRange の End に設定する
+ 			dr.End = &timeValue
+ 		} else {
+ 			dr.End = nil // 終了日が空文字列の場合は nil に設定する
+ 		}
+ 		// DateRange を inputValue に戻す
+ 		inputValue, err := NewInputValueFromDateRange(dr)
+ 		if err != nil {
+ 			return nil, perrors.Internalf("failed to create InputValue from DateRange: %w", err)
+ 		}
+ 
+ 		return InputValues{inputValue}, nil
+ 	}
+ 
+ 	DateRangeEnd_CSVValueConverter = CSVValueConverter{
+ 		ToCSVValue:   DateRangeEnd_ToCSVValue,
+ 		ToInputValue: DateRangeEnd_ToInputValue,
+ 	}
+ )
```

## apps/persia/app/domain/procedureform/csv_definitions.go
```diff
+ package procedureform
+ 
+ import (
+ 	"cmp"
+ 	"path/filepath"
+ 	"slices"
+ 	"time"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/handlers/http/oapi"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ type CSVDefinition struct {
+ 	Name                   string                           // CSVのファイル名、出力されるCSVファイルはこれに拡張子 .csv をつけたものになる
+ 	Dir                    string                           // Zipの中のディレクトリパス
+ 	HeaderDefinitions      CSVHeaderDefinitions             // ヘッダー定義
+ 	UploadMemberFilterFunc CSVUploadMemberFilterFunc        // CSVアップロードでの登録時に、各従業員の手続きステータスによって処理の分岐を設定するためのフィールド
+ 	ChangeStatusDocuments  ChangeStatusDocumentsOnCSVUpload // CSVアップロードでの登録時に、各従業員の書類のステータスを変更するためのフィールド
+ 	ChangeStatusPages      ChangeStatusPagesOnCSVUpload     // CSVアップロードでの登録時に、各従業員の各ページのステータスを変更するためのフィールド. スライスの前から順に処理される.
+ }
+ 
+ // GetPathInZip は、CSVファイルがZip内でどのパスに保存されるかを返す
+ func (d CSVDefinition) GetPathInZip() string {
+ 	pathInZip := d.Name + "_" + time.Now().Format("20060102_1504") + ".csv"
+ 	if d.Dir == "" {
+ 		return pathInZip
+ 	}
+ 	return filepath.Join(d.Dir, pathInZip)
+ }
+ 
+ type CSVDefinitions struct {
+ 	ZipName     string          // CSVダウンロード時のZipファイル名
+ 	Definitions []CSVDefinition // 各CSVファイルの定義リスト
+ }
+ 
+ func (ds CSVDefinitions) GetCSVDefinitionByCSVNumber() CSVDefinitionByCSVNumber {
+ 	res := make(CSVDefinitionByCSVNumber, len(ds.Definitions))
+ 	for i, d := range ds.Definitions {
+ 		res[UploadCSVNumber(i)] = d
+ 	}
+ 	return res
+ }
+ 
+ func (ds CSVDefinitions) HasDefinition() bool {
+ 	return len(ds.Definitions) > 0
+ }
+ 
+ func (ds CSVDefinitions) GetCSVDefinition(num UploadCSVNumber) (CSVDefinition, error) {
+ 	m := ds.GetCSVDefinitionByCSVNumber()
+ 	def, exists := m[num]
+ 	if !exists {
+ 		return CSVDefinition{}, perrors.BadRequestf("invalid uploadCSVNumber: %d", num)
+ 	}
+ 	return def, nil
+ }
+ 
+ func (ds CSVDefinitions) GetInputIDByUnitIDMap() map[domain.MembersFixedUnitID]InputID {
+ 	res := make(map[domain.MembersFixedUnitID]InputID, 0)
+ 	for _, d := range ds.Definitions {
+ 		for _, inputHeader := range d.HeaderDefinitions.InputHeaders {
+ 			input := inputHeader.Input
+ 			if input.UnitID.IsNone() {
+ 				continue
+ 			}
+ 			res[input.UnitID] = input.ID
+ 		}
+ 	}
+ 	return res
+ }
+ 
+ // 各従業員の手続きステータスごとにCSVアップロードの処理を制御するためのマップ
+ type CSVUploadHandlingType uint8
+ 
+ const (
+ 	// CSVアップロードによる値の登録を許可する
+ 	CSVUploadHandlingTypeAllow CSVUploadHandlingType = iota
+ 	// CSVアップロードによる値の登録を拒否し、エラーにする
+ 	CSVUploadHandlingTypeDeny
+ 	// CSVアップロードによる値の登録を無視する（CSV内に記載されていたとしても何もしない）
+ 	CSVUploadHandlingTypeIgnore
+ )
+ 
+ type ChangeStatusDocumentsOnCSVUpload struct {
+ 	EnabledDocumentIDs  []DocumentID
+ 	DisabledDocumentIDs []DocumentID
+ }
+ 
+ func (d ChangeStatusDocumentsOnCSVUpload) NeedsUpdate() bool {
+ 	return len(d.EnabledDocumentIDs) > 0 || len(d.DisabledDocumentIDs) > 0
+ }
+ 
+ type ChangeStatusPagesOnCSVUpload []ChangeStatusPageOnCSVUpload
+ 
+ type ChangeStatusPageOnCSVUpload struct {
+ 	PageID PageID
+ 
+ 	// PageStatusFrom のスライスに含まれる PageStatus を PageStatusTo へと変更する
+ 	PageStatusFrom []domain.MemberProcedureFormPageStatus
+ 	PageStatusTo   domain.MemberProcedureFormPageStatus
+ }
+ 
+ type (
+ 	// UploadCSVNumber は、アップロードされたCSVが CSVDefinition の何番目かを示す
+ 	// PageNumberForCSV と同じ意味ではあるが、CSVが必ずしもフォームのページに対応しているわけではなくなったため、再度定義し直す
+ 	UploadCSVNumber          = PageNumberForCSV
+ 	CSVDefinitionByCSVNumber map[UploadCSVNumber]CSVDefinition
+ )
+ 
+ type CSVNumToCSVNameConverter interface {
+ 	ConvertToCSVName(csvNum UploadCSVNumber) (string, error)
+ }
+ 
+ func (ns CSVDefinitionByCSVNumber) ConvertToCSVName(csvNum UploadCSVNumber) (string, error) {
+ 	def, ok := ns[csvNum]
+ 	if !ok {
+ 		return "", perrors.Internalf("failed to convert csvName to csvName, csvNum: %d", csvNum)
+ 	}
+ 
+ 	return def.Name, nil
+ }
+ 
+ func (ns CSVDefinitionByCSVNumber) ToResponse() oapi.ProcedureFormPageNames {
+ 	res := make(oapi.ProcedureFormPageNames, 0, len(ns))
+ 	for uploadCSVNumber, def := range ns {
+ 		res = append(res, oapi.ProcedureFormPageName{
+ 			Name:       def.Name,
+ 			PageNumber: int(uploadCSVNumber),
+ 		})
+ 	}
+ 
+ 	slices.SortFunc(res, func(a, b oapi.ProcedureFormPageName) int {
+ 		return cmp.Compare(a.PageNumber, b.PageNumber)
+ 	})
+ 
+ 	return res
+ }
```

## apps/persia/app/domain/procedureform/csv_definitions_test.go
```diff
+ package procedureform
+ 
+ import (
+ 	"testing"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/handlers/http/oapi"
+ 	"github.com/stretchr/testify/assert"
+ )
+ 
+ func TestCSVDefinitionByCSVNumber_ToResponse(t *testing.T) {
+ 	tests := []struct {
+ 		name string
+ 		ns   CSVDefinitionByCSVNumber
+ 		want oapi.ProcedureFormPageNames
+ 	}{
+ 		{
+ 			name: "empty",
+ 			ns:   CSVDefinitionByCSVNumber{},
+ 			want: oapi.ProcedureFormPageNames{},
+ 		},
+ 		{
+ 			name: "3 definitions",
+ 			ns: CSVDefinitionByCSVNumber{
+ 				0: {Name: "test0"},
+ 				1: {Name: "test1"},
+ 				2: {Name: "test2"},
+ 			},
+ 			want: oapi.ProcedureFormPageNames{
+ 				{
+ 					PageNumber: 0,
+ 					Name:       "test0",
+ 				},
+ 				{
+ 					PageNumber: 1,
+ 					Name:       "test1",
+ 				},
+ 				{
+ 					PageNumber: 2,
+ 					Name:       "test2",
+ 				},
+ 			},
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got := tt.ns.ToResponse()
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
```

## apps/persia/app/domain/procedureform/csv_error_download.go
```diff
+ package procedureform
+ 
+ import (
+ 	"encoding/json"
+ 	"errors"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ type CSVDownloadResult interface {
+ 	ResultType() domain.CSVDownloadResultType
+ 	MarshalJSON() ([]byte, error)
+ 	HasErrorDetails() bool
+ }
+ 
+ func NewCSVDownloadSuccess() CSVDownloadSuccess {
+ 	return CSVDownloadSuccess{}
+ }
+ 
+ type CSVDownloadSuccess struct{}
+ 
+ func (s CSVDownloadSuccess) ResultType() domain.CSVDownloadResultType {
+ 	return domain.CSVDownloadSuccess
+ }
+ 
+ func (s CSVDownloadSuccess) MarshalJSON() ([]byte, error) {
+ 	return nil, nil
+ }
+ 
+ func (s CSVDownloadSuccess) HasErrorDetails() bool {
+ 	return false
+ }
+ 
+ type CSVDownloadDataError struct {
+ 	Details domain.CSVDownloadErrorsToSaveV2
+ }
+ 
+ type CSVDownloadResultError interface {
+ 	error
+ 	CSVDownloadResult
+ }
+ 
+ func NewCSVDownloadDataError(details domain.CSVDownloadErrorsToSaveV2) CSVDownloadDataError {
+ 	return CSVDownloadDataError{Details: details}
+ }
+ 
+ type CSVDownloadDataErrorBuilder struct {
+ 	memberID       domain.MemberID
+ 	fileName       string
+ 	errorLocations []domain.ProcedureCSVCreationErrorLocation
+ }
+ 
+ func NewCSVDownloadDataErrorBuilder(memberID domain.MemberID, fileName string) *CSVDownloadDataErrorBuilder {
+ 	return &CSVDownloadDataErrorBuilder{
+ 		memberID:       memberID,
+ 		fileName:       fileName,
+ 		errorLocations: []domain.ProcedureCSVCreationErrorLocation{},
+ 	}
+ }
+ 
+ func (b *CSVDownloadDataErrorBuilder) AddErrorLocation(label string) {
+ 	b.errorLocations = append(b.errorLocations, domain.ProcedureCSVCreationErrorLocation{
+ 		FileName:   b.fileName,
+ 		InputLabel: label,
+ 	})
+ }
+ 
+ func (b *CSVDownloadDataErrorBuilder) Build() CSVDownloadDataError {
+ 	if len(b.errorLocations) == 0 {
+ 		return CSVDownloadDataError{
+ 			Details: domain.CSVDownloadErrorsToSaveV2{},
+ 		}
+ 	}
+ 	return CSVDownloadDataError{
+ 		Details: domain.CSVDownloadErrorsToSaveV2{
+ 			{
+ 				MemberID:       b.memberID.String(),
+ 				ErrorLocations: b.errorLocations,
+ 			},
+ 		},
+ 	}
+ }
+ 
+ func (e CSVDownloadDataError) Append(details domain.CSVDownloadErrorsToSaveV2) CSVDownloadDataError {
+ 	e.Details = append(e.Details, details...)
+ 	return e
+ }
+ 
+ func (e CSVDownloadDataError) ResultType() domain.CSVDownloadResultType {
+ 	return domain.CSVDownloadDataError
+ }
+ 
+ func (e CSVDownloadDataError) MarshalJSON() ([]byte, error) {
+ 	if !e.HasErrorDetails() {
+ 		return nil, nil
+ 	}
+ 	mergedByMemberID := e.Details.MergeErrorsByMemberID()
+ 	jsonData, err := json.Marshal(mergedByMemberID)
+ 	if err != nil {
+ 		return nil, perrors.Internal(err)
+ 	}
+ 	return jsonData, nil
+ }
+ 
+ func (e CSVDownloadDataError) HasErrorDetails() bool {
+ 	return len(e.Details) > 0
+ }
+ 
+ func (e CSVDownloadDataError) Error() string {
+ 	return "CSVDownloadDataError"
+ }
+ 
+ func AsCSVDownloadDataError(err error) *CSVDownloadDataError {
+ 	var dataError CSVDownloadDataError
+ 	if errors.As(err, &dataError) {
+ 		return &dataError
+ 	}
+ 	return nil
+ }
+ 
+ func NewCSVDownloadSystemError() CSVDownloadSystemError {
+ 	return CSVDownloadSystemError{}
+ }
+ 
+ type CSVDownloadSystemError struct{}
+ 
+ func (e CSVDownloadSystemError) ResultType() domain.CSVDownloadResultType {
+ 	return domain.CSVDownloadSystemError
+ }
+ 
+ func (e CSVDownloadSystemError) MarshalJSON() ([]byte, error) {
+ 	return nil, nil
+ }
+ 
+ func (e CSVDownloadSystemError) HasErrorDetails() bool {
+ 	return false
+ }
+ 
+ func (e CSVDownloadSystemError) Error() string {
+ 	return "CSVDownloadSystemError"
+ }
```

## apps/persia/app/domain/procedureform/csv_error_upload.go
```diff
+ package procedureform
+ 
+ import (
+ 	"encoding/json"
+ 	"errors"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ type CSVUploadResult interface {
+ 	ResultType() domain.CSVUploadResultType
+ 	MarshalJSON() ([]byte, error)
+ 	HasErrorDetails() bool
+ }
+ 
+ func NewCSVUploadResultSuccess() CSVUploadSuccess {
+ 	return CSVUploadSuccess{}
+ }
+ 
+ type CSVUploadSuccess struct{}
+ 
+ func (s CSVUploadSuccess) ResultType() domain.CSVUploadResultType {
+ 	return domain.CSVUploadSuccess
+ }
+ 
+ func (s CSVUploadSuccess) MarshalJSON() ([]byte, error) {
+ 	return nil, nil
+ }
+ 
+ func (s CSVUploadSuccess) HasErrorDetails() bool {
+ 	return false
+ }
+ 
+ type CSVUploadResultError interface {
+ 	error
+ 	CSVUploadResult
+ }
+ 
+ func NewCSVUploadDataError(details domain.CSVUploadDataErrorsToSaveV2) CSVUploadDataError {
+ 	return CSVUploadDataError{
+ 		Details: details,
+ 	}
+ }
+ 
+ type CSVUploadDataError struct {
+ 	Details domain.CSVUploadDataErrorsToSaveV2
+ }
+ 
+ func (e CSVUploadDataError) ResultType() domain.CSVUploadResultType {
+ 	return domain.CSVUploadDataError
+ }
+ 
+ func (e CSVUploadDataError) MarshalJSON() ([]byte, error) {
+ 	if !e.HasErrorDetails() {
+ 		return nil, nil
+ 	}
+ 	e.Details.SortByRowNumber()
+ 	jsonData, err := json.Marshal(e.Details)
+ 	if err != nil {
+ 		return nil, perrors.Internal(err)
+ 	}
+ 	return jsonData, nil
+ }
+ 
+ func (e CSVUploadDataError) HasErrorDetails() bool {
+ 	return len(e.Details) > 0
+ }
+ 
+ func (e CSVUploadDataError) AppendDetails(details domain.CSVUploadDataErrorsToSaveV2) CSVUploadDataError {
+ 	e.Details = append(e.Details, details...)
+ 	return e
+ }
+ 
+ func (e CSVUploadDataError) Error() string {
+ 	return "CSVUploadDataError"
+ }
+ 
+ func AsCSVUploadDataError(err error) *CSVUploadDataError {
+ 	var dataError CSVUploadDataError
+ 	if errors.As(err, &dataError) {
+ 		return &dataError
+ 	}
+ 	return nil
+ }
+ 
+ func NewCSVUploadReadingError(details domain.CSVUploadReadingErrorsToSaveV2) CSVUploadReadingError {
+ 	return CSVUploadReadingError{
+ 		Details: details,
+ 	}
+ }
+ 
+ type CSVUploadReadingError struct {
+ 	Details domain.CSVUploadReadingErrorsToSaveV2
+ }
+ 
+ func (e CSVUploadReadingError) ResultType() domain.CSVUploadResultType {
+ 	return domain.CSVUploadReadingError
+ }
+ 
+ func (e CSVUploadReadingError) MarshalJSON() ([]byte, error) {
+ 	if !e.HasErrorDetails() {
+ 		return nil, nil
+ 	}
+ 	e.Details.SortByRowNumber()
+ 	jsonData, err := json.Marshal(e.Details)
+ 	if err != nil {
+ 		return nil, perrors.Internal(err)
+ 	}
+ 	return jsonData, nil
+ }
+ 
+ func (e CSVUploadReadingError) HasErrorDetails() bool {
+ 	return len(e.Details) > 0
+ }
+ 
+ func (e CSVUploadReadingError) Error() string {
+ 	return "CSVUploadReadingError"
+ }
+ 
+ func AsCSVUploadReadingError(err error) *CSVUploadReadingError {
+ 	var readingError CSVUploadReadingError
+ 	if errors.As(err, &readingError) {
+ 		return &readingError
+ 	}
+ 	return nil
+ }
```

## apps/persia/app/domain/procedureform/csv_filter.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ type CSVUploadHandlingTypeByMemberProcedureStatus map[domain.MemberProcedureStatus]CSVUploadHandlingType
+ 
+ // 各従業員についてのデータを見て、CSVアップロードによる値の登録をするかどうかを判断するための構造体
+ type CSVUploadMemberFilter struct {
+ 	uploadMemberFilterFunc        CSVUploadMemberFilterFunc
+ 	memberProcedureStatusByMember map[domain.MemberID]domain.MemberProcedureStatus
+ 	bulkConfirmProcessingMembers  map[domain.MemberID]struct{} // 一括登録処理中のメンバー
+ }
+ 
+ func NewUploadMemberFilter(
+ 	uploadMemberFilterFunc CSVUploadMemberFilterFunc,
+ 	memberProcedureStatusByMember map[domain.MemberID]domain.MemberProcedureStatus,
+ 	bulkConfirmHistory *domain.ProcedureBulkConfirmHistory,
+ ) CSVUploadMemberFilter {
+ 	bulkConfirmProcessingMembers := map[domain.MemberID]struct{}{}
+ 	if bulkConfirmHistory != nil {
+ 		bulkConfirmProcessingMembers = bulkConfirmHistory.InProgressMemberIDsMap()
+ 	}
+ 	return CSVUploadMemberFilter{
+ 		uploadMemberFilterFunc:        uploadMemberFilterFunc,
+ 		memberProcedureStatusByMember: memberProcedureStatusByMember,
+ 		bulkConfirmProcessingMembers:  bulkConfirmProcessingMembers,
+ 	}
+ }
+ 
+ // 引数に指定された memberIDs のうち、CSVアップロードの対象となる memberIDs のみをフィルタリングして返す
+ func (f CSVUploadMemberFilter) FilterTargetMemberIDs(rowsByMember RowsByMember) (domain.MemberIDs, error) {
+ 	filteredMemberIDs := make(domain.MemberIDs, 0, len(rowsByMember))
+ 	for memberID, rows := range rowsByMember {
+ 		_, isBulkConfirmProcessing := f.bulkConfirmProcessingMembers[memberID]
+ 		if isBulkConfirmProcessing {
+ 			continue
+ 		}
+ 		memberProcedureStatus, ok := f.memberProcedureStatusByMember[memberID]
+ 		if !ok {
+ 			return nil, perrors.Internalf("memberProcedureStatus not found for memberID: %s", memberID)
+ 		}
+ 		uploadHandlingType := f.uploadMemberFilterFunc(CSVUploadMemberFilterArgs{
+ 			MemberProcedureStatus: memberProcedureStatus,
+ 		})
+ 		switch uploadHandlingType {
+ 		case CSVUploadHandlingTypeAllow:
+ 			filteredMemberIDs = append(filteredMemberIDs, memberID.String())
+ 		case CSVUploadHandlingTypeDeny:
+ 			if len(rows) < 1 {
+ 				// 実装ミス以外到達しない
+ 				return nil, perrors.Internalf("rows must have at least one row")
+ 			}
+ 			rowNumber := int(rows[0].Index.ToNumber())
+ 			// NOTE:
+ 			// 現在 UploadHandlingTypeDeny となるのは未依頼の従業員のときのみなので NotUnrequestedStatusMember というエラーにしているが
+ 			// 今後 uploadMemberFilterFunc の種類を増やして未依頼以外の従業員も拒否するようなケースが出てきた場合はエラー名とフロント側のエラーメッセージを修正する必要がある.
+ 			return nil, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: &rowNumber,
+ 					ErrorType: domain.ProcedureCSVErrorTypeExistNotUnrequestedStatusMember,
+ 				},
+ 			})
+ 		case CSVUploadHandlingTypeIgnore:
+ 			continue
+ 		default:
+ 			return nil, perrors.Internalf("unknown UploadHandlingType: %d", uploadHandlingType)
+ 		}
+ 	}
+ 	return filteredMemberIDs, nil
+ }
+ 
+ type CSVUploadMemberFilterFunc func(CSVUploadMemberFilterArgs) CSVUploadHandlingType
+ 
+ func CSVUploadMemberFilterDefault(args CSVUploadMemberFilterArgs) CSVUploadHandlingType {
+ 	if args.MemberProcedureStatus == domain.MemberProcedureStatusNone {
+ 		return CSVUploadHandlingTypeAllow
+ 	}
+ 	return CSVUploadHandlingTypeDeny
+ }
+ 
+ // 団体保険は手続き開始後でもCSVアップロード可能
+ func CSVUploadMemberFilterCanUploadAfterProcedureStarted(args CSVUploadMemberFilterArgs) CSVUploadHandlingType {
+ 	if args.MemberProcedureStatus == domain.MemberProcedureStatusInputConfirmed {
+ 		return CSVUploadHandlingTypeIgnore
+ 	}
+ 	return CSVUploadHandlingTypeAllow
+ }
+ 
+ type CSVUploadMemberFilterArgs struct {
+ 	MemberProcedureStatus domain.MemberProcedureStatus
+ }
```

## apps/persia/app/domain/procedureform/csv_format.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/strlib"
+ )
+ 
+ // formatToCSVValueInteger は、Integer型のDB値をCSV出力用に変換する処理
+ func formatToCSVValueInteger(v string) (string, error) {
+ 	if v == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// カンマ区切りにする
+ 	formatted, err := strlib.FormatStringNumber(v)
+ 	if err != nil {
+ 		return "", perrors.AsIs(err)
+ 	}
+ 	return formatted, nil
+ }
+ 
+ // formatToCSVValueFloat は、Float型のDB値をCSV出力用に変換する処理
+ func formatToCSVValueFloat(v string) (string, error) {
+ 	if v == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// カンマ区切りにする
+ 	formatted, err := strlib.FormatStringNumber(v)
+ 	if err != nil {
+ 		return "", perrors.AsIs(err)
+ 	}
+ 	return formatted, nil
+ }
+ 
+ // formatToCSVValueSingleSelection は、SingleSelection型のDB値をCSV出力用に変換する処理
+ func formatToCSVValueSingleSelection(input Input, v string) (string, error) {
+ 	return formatToCSVValueSelectionInput(input, v)
+ }
+ 
+ // formatToCSVValueToggle は、Toggle型のDB値をCSV出力用に変換する処理
+ func formatToCSVValueToggle(input Input, v string) (string, error) {
+ 	return formatToCSVValueSelectionInput(input, v)
+ }
+ 
+ // formatToCSVValueSelectionInput は、SelectionInputとToggle型のDB値をCSV出力用に変換する処理
+ func formatToCSVValueSelectionInput(input Input, v string) (string, error) {
+ 	if v == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// 値をラベルに変換する処理
+ 	label, found := input.SelectionOptions.ValueToLabel(v)
+ 	if found {
+ 		return label, nil
+ 	}
+ 	return "", perrors.BadRequestf("failed to convert value to label: %s", v)
+ }
+ 
+ // formatToCSVValueLargeToggleは、LargeToggle型のDB値をCSV出力用に変換する処理
+ func formatToCSVValueLargeToggle(input Input, v string) (string, error) {
+ 	if v == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// 値をラベルに変換する処理
+ 	label, found := input.LargeToggleOptions.ValueToLabel(v)
+ 	if found {
+ 		return label, nil
+ 	}
+ 	return "", perrors.BadRequestf("failed to convert value to label: %s", v)
+ }
```

## apps/persia/app/domain/procedureform/csv_header_definitions.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ // 手続きのCSVアップロード / ダウンロードにおけるヘッダー定義を表す構造体
+ type CSVHeaderDefinitions struct {
+ 	MemberHeaders CSVMemberHeaders
+ 	InputHeaders  CSVInputHeaders
+ }
+ 
+ // WriteHeaderToCSV は、CSV のヘッダーを CSVBuilder に書き込む
+ func (defs CSVHeaderDefinitions) WriteHeaderToCSV(builder domainCsv.CSVBuilder) {
+ 	currentColIdx := 0
+ 	for _, memberHeader := range defs.MemberHeaders {
+ 		memberHeader.Label.WriteToCSV(builder, domainCsv.ColumnIndex(currentColIdx))
+ 		currentColIdx++
+ 	}
+ 	for _, inputHeader := range defs.InputHeaders {
+ 		inputHeader.Label.WriteToCSV(builder, domainCsv.ColumnIndex(currentColIdx))
+ 		currentColIdx++
+ 	}
+ }
+ 
+ func (defs CSVHeaderDefinitions) ByInputID() map[InputID]CSVInputHeader {
+ 	res := make(map[InputID]CSVInputHeader, len(defs.InputHeaders))
+ 	for _, ih := range defs.InputHeaders {
+ 		res[ih.Input.ID] = ih
+ 	}
+ 	return res
+ }
+ 
+ func (defs CSVHeaderDefinitions) NewCSVHeaderDetector(csv domainCsv.CSV) (CSVHeaderDetector, error) {
+ 	if len(csv.Rows) < HeaderRowCount {
+ 		return nil, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{
+ 				ErrorType: domain.ProcedureCSVErrorTypeIncompleteCSVHeader,
+ 			},
+ 		})
+ 	}
+ 	if len(csv.Rows) == HeaderRowCount {
+ 		return nil, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{
+ 				ErrorType: domain.ProcedureCSVErrorTypeEmptyInput,
+ 			},
+ 		})
+ 	}
+ 	columnIndexToHeaderLabel, err := GetColumnIndexToCSVHeaderLabelMap(csv)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	headerLabelToMemberHeader := defs.MemberHeaders.KeyByLabel()
+ 	headerLabelToInputHeader := defs.InputHeaders.KeyByLabel()
+ 
+ 	columnIndexToMemberHeader := make(map[domainCsv.ColumnIndex]CSVMemberHeader, len(defs.MemberHeaders))
+ 	columnIndexToInputHeader := make(map[domainCsv.ColumnIndex]CSVInputHeader, len(defs.InputHeaders))
+ 
+ 	encounteredHeaderLabel := make(map[CSVHeaderLabel]struct{}, csv.CountColumns())
+ 	for colIdx, headerLabel := range columnIndexToHeaderLabel {
+ 		if _, exists := encounteredHeaderLabel[headerLabel]; exists {
+ 			return nil, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					ErrorType: domain.ProcedureCSVErrorTypeDuplicateHeader,
+ 				},
+ 			})
+ 		}
+ 		encounteredHeaderLabel[headerLabel] = struct{}{}
+ 		if memberHeader, ok := headerLabelToMemberHeader[headerLabel]; ok {
+ 			columnIndexToMemberHeader[colIdx] = memberHeader
+ 			continue
+ 		}
+ 		if inputHeader, ok := headerLabelToInputHeader[headerLabel]; ok {
+ 			columnIndexToInputHeader[colIdx] = inputHeader
+ 			continue
+ 		}
+ 		return nil, perrors.BadRequestf("unknown header label: %v", headerLabel)
+ 	}
+ 
+ 	return csvHeaderDetector{
+ 		columnIndexToMemberHeader: columnIndexToMemberHeader,
+ 		columnIndexToInputHeader:  columnIndexToInputHeader,
+ 	}, nil
+ }
+ 
+ type (
+ 	CSVMemberHeaders []CSVMemberHeader
+ 	CSVInputHeaders  []CSVInputHeader
+ )
+ 
+ func (mhs CSVMemberHeaders) KeyByLabel() map[CSVHeaderLabel]CSVMemberHeader {
+ 	byLabel := make(map[CSVHeaderLabel]CSVMemberHeader, len(mhs))
+ 	for _, mh := range mhs {
+ 		headerLabel := mh.Label
+ 		byLabel[headerLabel] = mh
+ 	}
+ 	return byLabel
+ }
+ 
+ func (ihs CSVInputHeaders) KeyByLabel() map[CSVHeaderLabel]CSVInputHeader {
+ 	byLabel := make(map[CSVHeaderLabel]CSVInputHeader, len(ihs))
+ 	for _, ih := range ihs {
+ 		headerLabel := ih.Label
+ 		byLabel[headerLabel] = ih
+ 	}
+ 	return byLabel
+ }
+ 
+ // 従業員情報を出力するヘッダーの定義
+ type CSVMemberHeader struct {
+ 	Label         CSVHeaderLabel
+ 	Calculate     func(CSVMemberHeaderSource) (string, error)
+ 	DetectionType CSVMemberHeaderType
+ }
+ 
+ func NewMemberHeader(label string) CSVHeaderLabel {
+ 	return CSVHeaderLabel{
+ 		FirstLine:  "",
+ 		SecondLine: "",
+ 		ThirdLine:  label,
+ 	}
+ }
+ 
+ // 各項目の値を出力するヘッダーの定義
+ type CSVInputHeader struct {
+ 	Input     Input
+ 	Label     CSVHeaderLabel
+ 	Converter CSVValueConverter
+ }
+ 
+ type CSVHeaderLabel struct {
+ 	FirstLine  string // ヘッダーの一行目
+ 	SecondLine string // ヘッダーの二行目
+ 	ThirdLine  string // ヘッダーの三行目
+ }
+ 
+ const HeaderRowCount = 3 // ヘッダーは3行で構成される
+ 
+ // WriteToCSV は、CSVHeaderLabel を CSVBuilder に書き込む
+ func (hl CSVHeaderLabel) WriteToCSV(builder domainCsv.CSVBuilder, colIdx domainCsv.ColumnIndex) {
+ 	builder.Write(0, colIdx, hl.FirstLine)
+ 	builder.Write(1, colIdx, hl.SecondLine)
+ 	builder.Write(2, colIdx, hl.ThirdLine)
+ }
+ 
+ func (hl CSVHeaderLabel) ToHierarchyLabel() string {
+ 	hierarchyLabel := hl.FirstLine
+ 
+ 	if hl.SecondLine != "" {
+ 		hierarchyLabel += ">" + hl.SecondLine
+ 	}
+ 	if hl.ThirdLine != "" {
+ 		hierarchyLabel += ">" + hl.ThirdLine
+ 	}
+ 
+ 	return hierarchyLabel
+ }
+ 
+ // CSVMemberHeaderType は、CSVの従業員情報を指すヘッダーの種類を表す
+ type CSVMemberHeaderType uint8
+ 
+ const (
+ 	CSVMemberHeaderTypeOther          CSVMemberHeaderType = iota // 下2つ以外
+ 	CSVMemberHeaderTypeEmployeeNumber                            // 従業員番号に対応する行
+ 	CSVMemberHeaderTypeEmailAddress                              // メールアドレスに対応する行
+ )
+ 
+ type CSVMemberHeaderSource struct {
+ 	Member                domain.Member
+ 	MemberProcedureStatus domain.MemberProcedureStatus
+ }
+ 
+ func NewCSVMemberHeaderSourceMap(
+ 	members domain.Members,
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ ) (map[domain.MemberID]CSVMemberHeaderSource, error) {
+ 	res := make(map[domain.MemberID]CSVMemberHeaderSource, len(members))
+ 	for _, member := range members {
+ 		domainMemberID := domain.MemberID(member.ID)
+ 		memberProcedureStatus, exists := memberProcedureStatusMap[domainMemberID]
+ 		if !exists {
+ 			// 実装ミス以外到達しない
+ 			return nil, perrors.Internalf("memberID key: %s not found in memberProcedureStatusMap", domainMemberID)
+ 		}
+ 		res[domainMemberID] = CSVMemberHeaderSource{
+ 			Member:                member,
+ 			MemberProcedureStatus: memberProcedureStatus,
+ 		}
+ 	}
+ 	return res, nil
+ }
```

## apps/persia/app/domain/procedureform/csv_header_detector.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ // CSVHeaderDetectorは、列インデックスからCSVヘッダーを取得するためのIF
+ type CSVHeaderDetector interface {
+ 	NewCSVMemberDetector(members domain.Members) (CSVMemberDetector, error)
+ 	GetInputHeader(colIdx domainCsv.ColumnIndex) (CSVInputHeader, error)
+ 	GetMemberHeader(colIdx domainCsv.ColumnIndex) (CSVMemberHeader, error)
+ 	IsInputHeader(colIdx domainCsv.ColumnIndex) bool
+ 	IsMemberHeader(colIdx domainCsv.ColumnIndex) bool
+ 	GetInputIDsToBeDeletedOnCSVUpload(form Form) []InputID
+ }
+ 
+ type csvHeaderDetector struct {
+ 	columnIndexToMemberHeader map[domainCsv.ColumnIndex]CSVMemberHeader
+ 	columnIndexToInputHeader  map[domainCsv.ColumnIndex]CSVInputHeader
+ }
+ 
+ // CSVの列インデックスから InputHeader を取得する
+ func (hd csvHeaderDetector) GetInputHeader(colIdx domainCsv.ColumnIndex) (CSVInputHeader, error) {
+ 	inputHeader, ok := hd.columnIndexToInputHeader[colIdx]
+ 	if !ok {
+ 		return CSVInputHeader{}, perrors.Internalf("unknown input header for column index: %d", colIdx)
+ 	}
+ 	return inputHeader, nil
+ }
+ 
+ // CSVの列インデックスから MemberHeader を取得する
+ func (hd csvHeaderDetector) GetMemberHeader(colIdx domainCsv.ColumnIndex) (CSVMemberHeader, error) {
+ 	memberHeader, ok := hd.columnIndexToMemberHeader[colIdx]
+ 	if !ok {
+ 		return CSVMemberHeader{}, perrors.Internalf("unknown member header for column index: %d", colIdx)
+ 	}
+ 	return memberHeader, nil
+ }
+ 
+ // 指定されたCSVの列インデックスに対応するヘッダーが InputHeader かどうかを判定する
+ func (hd csvHeaderDetector) IsInputHeader(colIdx domainCsv.ColumnIndex) bool {
+ 	_, exists := hd.columnIndexToInputHeader[colIdx]
+ 	return exists
+ }
+ 
+ // 指定されたCSVの列インデックスに対応するヘッダーが MemberHeader かどうかを判定する
+ func (hd csvHeaderDetector) IsMemberHeader(colIdx domainCsv.ColumnIndex) bool {
+ 	_, exists := hd.columnIndexToMemberHeader[colIdx]
+ 	return exists
+ }
+ 
+ // MemberDetectorを作成する
+ func (hd csvHeaderDetector) NewCSVMemberDetector(members domain.Members) (CSVMemberDetector, error) {
+ 	emailAddressColumnIndex, employeeNumberColumnIndex, err := hd.getMemberDetectionColumnIndexes()
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	membersByDetectKey := make(map[csvMemberDetectKey]domain.Member, len(members))
+ 	for _, member := range members {
+ 		detectKey := csvMemberDetectKey{
+ 			emailAddress:   member.Email,
+ 			employeeNumber: member.EmployeeNumber,
+ 		}
+ 		membersByDetectKey[detectKey] = member
+ 	}
+ 
+ 	return csvMemberDetector{
+ 		membersByDetectKey:        membersByDetectKey,
+ 		emailAddressColumnIndex:   emailAddressColumnIndex,
+ 		employeeNumberColumnIndex: employeeNumberColumnIndex,
+ 	}, nil
+ }
+ 
+ // GetInputIDsToBeDeletedOnCSVUpload は CSVアップロードにより一旦削除される InputIDs を取得します
+ // 削除対象となる Input は次の2つ
+ // 1. アップロードされた CSV の各カラムに対応するInput
+ // 2. アップロードされた CSV のカラムの中に MultipleSection に含まれる Input があれば、その MultipleSection 内の CSVアップロード対象外となっている Input
+ // 【2に該当するInputを削除する理由】
+ //   - 前提として、CSVアップロードは「追加」ではなく「上書き」の操作である.
+ //   - 例えば、すでに保険情報が3つ登録されているとする. そこに保険情報が2つ入ったCSVをアップロードした場合、（CSVアップロードは上書きの操作のため）アップロード後の状態としては保険情報は2つになってほしい.
+ //   - しかし、ただCSVに記載されている列に対応するInputの値を消すだけだと、3つめの保険の「給与の支払者の確認」（チェックボックス）などが残ってしまい、保険情報が2つにならない.
+ //   - これを回避するために、MultipleSectionに含まれるInputのうち、CSVアップロード対象外となっているInputも削除対象とする.
+ func (hd csvHeaderDetector) GetInputIDsToBeDeletedOnCSVUpload(form Form) []InputID {
+ 	sectionByInputID := form.GetSectionByInputID()
+ 
+ 	affectedIDs := make([]InputID, 0, len(hd.columnIndexToInputHeader))
+ 	// CSVアップロード対象となっている Input が属する MultipleSection の SectionID を記録
+ 	multipleSectionIDSet := make(map[SectionID]struct{})
+ 
+ 	for _, inputHeader := range hd.columnIndexToInputHeader {
+ 		// 1. アップロードされた CSV の各カラムに対応するInput
+ 		affectedIDs = append(affectedIDs, inputHeader.Input.ID)
+ 		section := sectionByInputID[inputHeader.Input.ID]
+ 		if section.Multiple {
+ 			multipleSectionIDSet[section.ID] = struct{}{}
+ 		}
+ 	}
+ 
+ 	for _, page := range form.Pages {
+ 		for _, section := range page.Sections {
+ 			if _, exists := multipleSectionIDSet[section.ID]; exists {
+ 				for _, row := range section.Rows {
+ 					for _, input := range row.Inputs {
+ 						if IsExcludedInputFromCSV(input) {
+ 							// 2. アップロードされた CSV のカラムの中に MultipleSection に含まれる Input があれば、
+ 							// その MultipleSection 内の CSVアップロード対象外となっている Input
+ 							affectedIDs = append(affectedIDs, input.ID)
+ 						}
+ 					}
+ 				}
+ 			}
+ 		}
+ 	}
+ 	return affectedIDs
+ }
+ 
+ // getMemberDetectionColumnIndexesは、メールアドレス と 従業員番号 の列インデックスを取得する
+ func (hd csvHeaderDetector) getMemberDetectionColumnIndexes() (domainCsv.ColumnIndex, domainCsv.ColumnIndex, error) {
+ 	var emailAddressColumnIndex *domainCsv.ColumnIndex
+ 	var employeeNumberColumnIndex *domainCsv.ColumnIndex
+ 	for colIdx, memberHeader := range hd.columnIndexToMemberHeader {
+ 		switch memberHeader.DetectionType {
+ 		case CSVMemberHeaderTypeEmailAddress:
+ 			if emailAddressColumnIndex != nil {
+ 				return 0, 0, perrors.BadRequestf("multiple email address headers found")
+ 			}
+ 			emailAddressColumnIndex = &colIdx
+ 		case CSVMemberHeaderTypeEmployeeNumber:
+ 			if employeeNumberColumnIndex != nil {
+ 				return 0, 0, perrors.BadRequestf("multiple employee number headers found")
+ 			}
+ 			employeeNumberColumnIndex = &colIdx
+ 		}
+ 	}
+ 
+ 	if emailAddressColumnIndex == nil || employeeNumberColumnIndex == nil {
+ 		return 0, 0, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{
+ 				ErrorType: domain.ProcedureCSVErrorTypeNotIncludedEmployeeNumberOrMailaddress,
+ 			},
+ 		})
+ 	}
+ 	return *emailAddressColumnIndex, *employeeNumberColumnIndex, nil
+ }
```

## apps/persia/app/domain/procedureform/csv_headers.go
```diff
+ package procedureform
+ 
+ import (
+ 	"slices"
+ 
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ // 各フォームを構成する要素について、カスタマイズしたいヘッダー情報があれば設定する
+ type CSVHeaderGenerationConfig struct {
+ 	BySection    map[SectionID]CSVHeaderOption
+ 	BySectionRow map[SectionRowID]CSVHeaderOption
+ 	ByInput      map[InputID]CSVHeaderOption
+ }
+ 
+ type CSVHeaderOption struct {
+ 	Skip         bool
+ 	OverrideName string
+ }
+ 
+ func (cfg CSVHeaderGenerationConfig) skipSection(sectionID SectionID) bool {
+ 	if option, ok := cfg.BySection[sectionID]; ok {
+ 		return option.Skip
+ 	}
+ 	return false
+ }
+ 
+ func (cfg CSVHeaderGenerationConfig) skipSectionRow(sectionRowID SectionRowID) bool {
+ 	if option, ok := cfg.BySectionRow[sectionRowID]; ok {
+ 		return option.Skip
+ 	}
+ 	return false
+ }
+ 
+ func (cfg CSVHeaderGenerationConfig) skipInput(inputID InputID) bool {
+ 	if option, ok := cfg.ByInput[inputID]; ok {
+ 		return option.Skip
+ 	}
+ 	return false
+ }
+ 
+ func (option CSVHeaderOption) getName(defaultName string) string {
+ 	if option.Skip {
+ 		return ""
+ 	}
+ 	if option.OverrideName != "" {
+ 		return option.OverrideName
+ 	}
+ 	return defaultName
+ }
+ 
+ func (cfg CSVHeaderGenerationConfig) GetSectionName(section Section) string {
+ 	if option, ok := cfg.BySection[section.ID]; ok {
+ 		return option.getName(section.Name)
+ 	}
+ 	return section.Name
+ }
+ 
+ func (cfg CSVHeaderGenerationConfig) GetRowName(row SectionRow) string {
+ 	if option, ok := cfg.BySectionRow[row.ID]; ok {
+ 		return option.getName(row.Label)
+ 	}
+ 	return row.Label
+ }
+ 
+ func (cfg CSVHeaderGenerationConfig) GetInputName(input Input) string {
+ 	if option, ok := cfg.ByInput[input.ID]; ok {
+ 		return option.getName(input.Label)
+ 	}
+ 	return input.Label
+ }
+ 
+ // ToCSVInputHeadersFromPageWithConfig は Page から InputHeaders を生成する. CSVHeaderGenerationConfig を使用すればヘッダーのカスタマイズが可能
+ func ToCSVInputHeadersFromPageWithConfig(page Page, cfg CSVHeaderGenerationConfig) CSVInputHeaders {
+ 	result := make(CSVInputHeaders, 0)
+ 	for _, section := range page.Sections {
+ 		if cfg.skipSection(section.ID) {
+ 			continue
+ 		}
+ 		for _, row := range section.Rows {
+ 			if cfg.skipSectionRow(row.ID) {
+ 				continue
+ 			}
+ 			for _, input := range row.Inputs {
+ 				if cfg.skipInput(input.ID) || IsExcludedInputFromCSV(input) {
+ 					continue
+ 				}
+ 				label := CSVHeaderLabel{
+ 					FirstLine:  cfg.GetSectionName(section),
+ 					SecondLine: cfg.GetRowName(row),
+ 					ThirdLine:  cfg.GetInputName(input),
+ 				}
+ 				headers := CreateCSVInputHeadersByInput(input, label)
+ 				result = append(result, headers...)
+ 			}
+ 		}
+ 	}
+ 	return result
+ }
+ 
+ func ToCSVInputHeadersFromPage(page Page) CSVInputHeaders {
+ 	return ToCSVInputHeadersFromPageWithConfig(page, CSVHeaderGenerationConfig{})
+ }
+ 
+ // CSVアップロードにより更新しないInputIDの条件. CSVアップロードをするためにダウンロードするCSVにも含まれない.
+ func IsExcludedInputFromCSV(input Input) bool {
+ 	isExcludedInputType := slices.Contains([]InputType{InputTypeCheckboxGroup, InputTypeFile, InputTypeCheckbox}, input.Type)
+ 	if isExcludedInputType {
+ 		return true
+ 	}
+ 
+ 	if len(input.CalculatedFrom) > 0 {
+ 		return true
+ 	}
+ 	return false
+ }
+ 
+ // InputType をみて必要なヘッダーを生成する（返り値の InputHeaders は基本1つだが、DateRangeの場合は2つになる）
+ func CreateCSVInputHeadersByInput(
+ 	input Input,
+ 	label CSVHeaderLabel,
+ ) CSVInputHeaders {
+ 	switch input.Type {
+ 	case InputTypeDateRange:
+ 		// DateRange の場合は 開始日 と 終了日 で2つのヘッダーを生成する
+ 		// ThirdLineの「開始日」「終了日」は、今はハードコーディングで設定しているが、
+ 		// 将来 DateRange の Start と End を表すものが「開始日」「終了日」に限らなくなった場合は、この部分を修正する必要がある
+ 		return CSVInputHeaders{
+ 			{
+ 				Input: input,
+ 				Label: CSVHeaderLabel{
+ 					FirstLine:  label.FirstLine,
+ 					SecondLine: label.SecondLine,
+ 					ThirdLine:  label.ThirdLine + " 開始日",
+ 				},
+ 				Converter: DateRangeStart_CSVValueConverter,
+ 			},
+ 			{
+ 				Input: input,
+ 				Label: CSVHeaderLabel{
+ 					FirstLine:  label.FirstLine,
+ 					SecondLine: label.SecondLine,
+ 					ThirdLine:  label.ThirdLine + " 終了日",
+ 				},
+ 				Converter: DateRangeEnd_CSVValueConverter,
+ 			},
+ 		}
+ 	default:
+ 		return CSVInputHeaders{
+ 			{
+ 				Input: input,
+ 				Label: CSVHeaderLabel{
+ 					FirstLine:  label.FirstLine,
+ 					SecondLine: label.SecondLine,
+ 					ThirdLine:  label.ThirdLine,
+ 				},
+ 				Converter: GetCSVValueConverterByInputType(input.Type),
+ 			},
+ 		}
+ 	}
+ }
+ 
+ // GetCSVValueConverterByInputType は、InputType に応じた適切な CSVValueConverter を返す
+ func GetCSVValueConverterByInputType(inputType InputType) CSVValueConverter {
+ 	switch inputType {
+ 	case InputTypeText, InputTypeTextarea:
+ 		return DefaultType_CSVValueConverter
+ 	case InputTypeInteger:
+ 		return Integer_CSVValueConverter
+ 	case InputTypeFloat:
+ 		return Float_CSVValueConverter
+ 	case InputTypeDate:
+ 		return Date_CSVValueConverter
+ 	case InputTypeSingleSelection:
+ 		return SingleSelection_CSVValueConverter
+ 	case InputTypeToggle:
+ 		return Toggle_CSVValueConverter
+ 	case InputTypeLargeToggle:
+ 		return LargeToggle_CSVValueConverter
+ 	default:
+ 		// InputTypeDateRange はこの関数の呼び出し元で処理されるため、ここでは対応しない
+ 		// また、その他の InputType (InputTypeCheckbox, InputTypeCheckboxGroup, InputTypeFile) はCSVアップロードの対象外のためここでは対応しない
+ 		// もしInputTypeを新たに追加したなどでここに到達してしまった場合、CSVValueConverter が必要であればこの case文 に追加すること.
+ 		panic("unsupported InputType:" + string(inputType) + ". If this type needs CSV conversion, add a case for it in GetCSVValueConverterByInputType.")
+ 	}
+ }
+ 
+ // GetColumnIndexToCSVHeaderLabelMap は ColumnIndex から CSVHeaderLabel へのマッピングを作成する
+ func GetColumnIndexToCSVHeaderLabelMap(csv domainCsv.CSV) (map[domainCsv.ColumnIndex]CSVHeaderLabel, error) {
+ 	columnIndexToHeaderLabel := make(map[domainCsv.ColumnIndex]CSVHeaderLabel)
+ 	colCount := csv.CountColumns()
+ 	for colIdx := range colCount {
+ 		headerLabel, err := getCSVHeaderLabel(csv, domainCsv.ColumnIndex(colIdx))
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 		columnIndexToHeaderLabel[domainCsv.ColumnIndex(colIdx)] = headerLabel
+ 	}
+ 	return columnIndexToHeaderLabel, nil
+ }
+ 
+ // getCSVHeaderLabel は指定された ColumnIndex の CSVHeaderLabel を取得する
+ func getCSVHeaderLabel(csv domainCsv.CSV, colIdx domainCsv.ColumnIndex) (CSVHeaderLabel, error) {
+ 	cell0, err := csv.GetCell(0, colIdx)
+ 	if err != nil {
+ 		return CSVHeaderLabel{}, perrors.AsIs(err)
+ 	}
+ 	cell1, err := csv.GetCell(1, colIdx)
+ 	if err != nil {
+ 		return CSVHeaderLabel{}, perrors.AsIs(err)
+ 	}
+ 	cell2, err := csv.GetCell(2, colIdx)
+ 	if err != nil {
+ 		return CSVHeaderLabel{}, perrors.AsIs(err)
+ 	}
+ 
+ 	return CSVHeaderLabel{
+ 		FirstLine:  cell0.Value,
+ 		SecondLine: cell1.Value,
+ 		ThirdLine:  cell2.Value,
+ 	}, nil
+ }
```

## apps/persia/app/domain/procedureform/csv_input_identifier_provider.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/gofrs/uuid/v5"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ // CSVInputIdentifierProviderは、Member と Cell から CSVInputIdentifier(SectionID, GroupID, InputIDの組)を取得するためのIF
+ type CSVInputIdentifierProvider interface {
+ 	// GetCSVInputIdentifier は、Member と Cell から CSVInputIdentifier を取得する. 第二返り値の bool はその Cell の値をスキップすべきかどうかを表す. テストでUUIDの生成部分を固定するために、引数でUUIDを生成する関数を渡している.
+ 	GetCSVInputIdentifier(memberID domain.MemberID, cell domainCsv.Cell, newUUIDFunc func() (uuid.UUID, error)) (CSVInputIdentifier, bool, error)
+ 	// GetRowIndexByMemberIDAndIdentifier は、MemberID と CSVInputIdentifier から RowIndex を取得する.
+ 	GetRowIndexByMemberIDAndIdentifier(memberID domain.MemberID, identifier CSVInputIdentifier) (domainCsv.RowIndex, error)
+ }
+ 
+ type CSVInputIdentifier struct {
+ 	SectionID SectionID
+ 	GroupID   GroupID
+ 	InputID   InputID
+ }
+ 
+ type assignedGroupIDHolderKey struct {
+ 	MemberID  domain.MemberID
+ 	SectionID SectionID
+ 	RowIndex  domainCsv.RowIndex
+ }
+ 
+ type savedGroupIDHolderKey struct {
+ 	MemberID   domain.MemberID
+ 	SectionID  SectionID
+ 	GroupIndex int
+ }
+ 
+ type csvInputIdentifierProvider struct {
+ 	// inputID -> Section
+ 	sectionByInputID map[InputID]Section
+ 	// cell.ColumnIndex から InputHeader を取得するために用いる
+ 	headerDetector CSVHeaderDetector
+ 	// memberID -> rowIndex -> groupIndex
+ 	memberRowToGroupIndex map[domain.MemberID]map[domainCsv.RowIndex]int
+ 	// memberID + sectionID + rowIndex -> getGroupIDの中で採番したgroupID
+ 	assignedGroupIDHolder map[assignedGroupIDHolderKey]GroupID
+ 	// memberID + sectionID + groupIndex -> すでに採番されてDBに保存されているgroupID
+ 	savedGroupIDHolder map[savedGroupIDHolderKey]GroupID
+ 	// memberID + CSVInputIdentifier -> rowIndex
+ 	rowIndexByMemberIDAndIdentifier map[domain.MemberID]map[CSVInputIdentifier]domainCsv.RowIndex
+ }
+ 
+ func NewCSVInputIdentifierProvider(sectionByInputID map[InputID]Section, headerDetector CSVHeaderDetector, formValuesByMember map[domain.MemberID]FormValues) CSVInputIdentifierProvider {
+ 	savedGroupIDHolder := make(map[savedGroupIDHolderKey]GroupID)
+ 	for memberID, formValues := range formValuesByMember {
+ 		for inputID, groupedInputValuesList := range formValues.GetAllGroupedInputValuesList() {
+ 			for groupIndex, groupedInputValues := range groupedInputValuesList {
+ 				section, ok := sectionByInputID[inputID]
+ 				if !ok {
+ 					// 通常到達しない. ただ、Input をリリース後に違う Section に移動させた場合などに起き得る.
+ 					// その場合にエラーにしてしまうと Input の移動をさせる前にフォームの値を保存したユーザーについてはCSVアップロードができなくなるためここではエラーにせずcontinueする.
+ 					continue
+ 				}
+ 				key := savedGroupIDHolderKey{
+ 					MemberID:   memberID,
+ 					SectionID:  section.ID,
+ 					GroupIndex: groupIndex,
+ 				}
+ 				savedGroupIDHolder[key] = groupedInputValues.groupID
+ 			}
+ 		}
+ 	}
+ 	return csvInputIdentifierProvider{
+ 		sectionByInputID:                sectionByInputID,
+ 		headerDetector:                  headerDetector,
+ 		savedGroupIDHolder:              savedGroupIDHolder,                                                  // DBの値を用いて初期化
+ 		memberRowToGroupIndex:           make(map[domain.MemberID]map[domainCsv.RowIndex]int),                // getGroupID の中で中身が詰められていく.
+ 		assignedGroupIDHolder:           make(map[assignedGroupIDHolderKey]GroupID),                          // getGroupID の中で中身が詰められていく.
+ 		rowIndexByMemberIDAndIdentifier: make(map[domain.MemberID]map[CSVInputIdentifier]domainCsv.RowIndex), // GetCSVInputIdentifier の中で中身が詰められていく.
+ 	}
+ }
+ 
+ func (p csvInputIdentifierProvider) GetCSVInputIdentifier(memberID domain.MemberID, cell domainCsv.Cell, newUUIDFunc func() (uuid.UUID, error)) (CSVInputIdentifier, bool, error) {
+ 	inputHeader, err := p.headerDetector.GetInputHeader(cell.ColumnIndex)
+ 	if err != nil {
+ 		return CSVInputIdentifier{}, false, perrors.AsIs(err)
+ 	}
+ 	inputID := inputHeader.Input.ID
+ 
+ 	section, err := p.getSection(inputID)
+ 	if err != nil {
+ 		return CSVInputIdentifier{}, false, perrors.AsIs(err)
+ 	}
+ 
+ 	groupID, shouldSkip, err := p.getGroupID(memberID, section, cell.RowIndex, newUUIDFunc)
+ 	if err != nil {
+ 		return CSVInputIdentifier{}, false, perrors.AsIs(err)
+ 	}
+ 
+ 	if shouldSkip {
+ 		return CSVInputIdentifier{}, true, nil
+ 	}
+ 
+ 	rowIndexByIdentifier, ok := p.rowIndexByMemberIDAndIdentifier[memberID]
+ 	if !ok {
+ 		rowIndexByIdentifier = map[CSVInputIdentifier]domainCsv.RowIndex{}
+ 		p.rowIndexByMemberIDAndIdentifier[memberID] = rowIndexByIdentifier
+ 	}
+ 
+ 	rowIndexByIdentifier[CSVInputIdentifier{
+ 		SectionID: section.ID,
+ 		GroupID:   groupID,
+ 		InputID:   inputID,
+ 	}] = cell.RowIndex
+ 
+ 	return CSVInputIdentifier{
+ 		SectionID: section.ID,
+ 		GroupID:   groupID,
+ 		InputID:   inputID,
+ 	}, false, nil
+ }
+ 
+ func (p csvInputIdentifierProvider) getSection(inputID InputID) (Section, error) {
+ 	section, ok := p.sectionByInputID[inputID]
+ 	if !ok {
+ 		// 実装ミス以外でここに到達することはない
+ 		return Section{}, perrors.Internalf("inputID %s not found in section", inputID)
+ 	}
+ 
+ 	return section, nil
+ }
+ 
+ /*
+ getGroupID は、Member, Section, RowIndex に基づいて GroupID を決定する。
+ また第二返り値の bool は、その Cell の値をスキップすべきかどうかを表す。これは、SingleSection 内の Input の2行目以降の値は無視するために使用される.
+ 
+ getGroupID の処理の流れ
+ 
+  1. キャッシュの確認:
+     まずassignedGroupIDHolderをチェックする。
+     これは、今回のCSVアップロードの処理中に、同じ memberID, sectionID, rowIndex の組み合わせですでに GroupID を払い出したことがあるかを記録するキャッシュ。
+     すでにあれば、計算を省略して即座にそのGroupIDを返す。
+ 
+  2. RowIndex から GroupIndex への変換:
+     memberRowToGroupIndex を使い、RowIndex を GroupIndex に変換する。
+     各メンバーについて初めて登場した RowIndex には GroupIndex = 0 を、次に出てきた別の RowIndex には 1を...というように、登場順に連番を割り当てる。
+ 
+  3. 既存のGroupIDがあるかの確認:
+     変換した GroupIndex と savedGroupIDHolder を使って、既存のGroupIDがあるかを確認する。
+     このマップには、データベースにすでに保存されている GroupID が事前に格納されている。
+     ここで GroupID が見つかった場合、それは「既存Groupの更新」を意味する。
+ 
+  4. 新規のGroupIDの採番:
+     savedGroupIDHolder に GroupID がなかった場合、それは「新規Groupの追加」を意味する。
+     - MultipleSection 内の Input の場合：新しいUUIDを採番して GroupID とする。
+     - SingleSection 内の Input の場合：
+     - GroupIndex が 0 ならば、DefaultGroupID を割り当てる。
+     - GroupIndex が 1 以上ならば、SingleSection内の2行目以降となるので、この行の処理をスキップするよう true を返す。
+ 
+  5. キャッシュを保存:
+     最終的に決定した GroupID を、手順1で使った assignedGroupIDHolder に格納する。
+ 
+ ■ CSVデータ例
+ | ... | 氏   | 名     | 家族情報 > 氏 | 家族情報 > 名 |
+ |-----|------|--------|-------------|-------------|
+ | ... | 山田 | 太郎    | 家族1氏      | 家族1名      | <-- RowIndex: 5, GroupIndex: 0 (DBに既存Groupあり -> savedGroupIDHolder から取得)
+ | ... | 山田 | 太郎    | 家族2氏      | 家族2名      | <-- RowIndex: 6, GroupIndex: 1 (DBに既存Groupあり -> savedGroupIDHolder から取得)
+ | ... | 山田 | 太郎    | 家族3氏      | 家族3名      | <-- RowIndex: 7, GroupIndex: 2 (DBに既存Groupなし -> 新規にUUIDを採番)
+ */
+ func (p csvInputIdentifierProvider) getGroupID(memberID domain.MemberID, section Section, rowIndex domainCsv.RowIndex, newUUIDFunc func() (uuid.UUID, error)) (GroupID, bool, error) {
+ 	// 1.キャッシュの確認
+ 	assignedGroupIDKey := assignedGroupIDHolderKey{MemberID: memberID, SectionID: section.ID, RowIndex: rowIndex}
+ 	if gid, ok := p.assignedGroupIDHolder[assignedGroupIDKey]; ok {
+ 		return gid, false, nil
+ 	}
+ 
+ 	// 2. RowIndex から GroupIndex への変換
+ 	groupIndex := p.getOrAssignGroupIndex(memberID, rowIndex)
+ 
+ 	// 3. 既存のGroupIDがあるかの確認 / 4. 新規のGroupIDの採番
+ 	groupID, shouldSkip, err := p.findOrGenerateGroupID(memberID, section, groupIndex, newUUIDFunc)
+ 	if err != nil {
+ 		return uuid.Nil, false, perrors.AsIs(err)
+ 	}
+ 	if shouldSkip {
+ 		return uuid.Nil, true, nil
+ 	}
+ 
+ 	// 5. キャッシュを保存
+ 	p.assignedGroupIDHolder[assignedGroupIDKey] = groupID
+ 	return groupID, false, nil
+ }
+ 
+ // getOrAssignGroupIndex は、memberID と rowIndex に基づいて、 groupIndex を返す。
+ // 同じ memberID と rowIndex には常に同じ groupIndex を返す。
+ func (p csvInputIdentifierProvider) getOrAssignGroupIndex(memberID domain.MemberID, rowIndex domainCsv.RowIndex) int {
+ 	if _, ok := p.memberRowToGroupIndex[memberID]; !ok {
+ 		p.memberRowToGroupIndex[memberID] = make(map[domainCsv.RowIndex]int)
+ 	}
+ 	rowMap := p.memberRowToGroupIndex[memberID]
+ 
+ 	groupIndex, ok := rowMap[rowIndex]
+ 	if !ok {
+ 		// この memberID のこの rowIndex は初めてなので、新しいgroupIndexを採番する
+ 		groupIndex = len(rowMap)
+ 		rowMap[rowIndex] = groupIndex
+ 	}
+ 	return groupIndex
+ }
+ 
+ // findOrGenerateGroupID は、DBに保存済みのGroupIDを探し、なければ新しいGroupIDを生成する。
+ func (p csvInputIdentifierProvider) findOrGenerateGroupID(memberID domain.MemberID, section Section, groupIndex int, newUUIDFunc func() (uuid.UUID, error)) (GroupID, bool, error) {
+ 	// DBに保存済みの　GroupID　があるか確認
+ 	savedGroupIdKey := savedGroupIDHolderKey{MemberID: memberID, SectionID: section.ID, GroupIndex: groupIndex}
+ 	if groupID, ok := p.savedGroupIDHolder[savedGroupIdKey]; ok {
+ 		return groupID, false, nil
+ 	}
+ 
+ 	// 既存の GroupID がなかったので、新規に生成する
+ 	return p.generateNewGroupID(section, groupIndex, newUUIDFunc)
+ }
+ 
+ // generateNewGroupID は、Sectionが Single なのか Multiple なのかに応じて新しいGroupIDを生成する。
+ func (p csvInputIdentifierProvider) generateNewGroupID(section Section, groupIndex int, newUUIDFunc func() (uuid.UUID, error)) (GroupID, bool, error) {
+ 	if section.Multiple {
+ 		// MultipleSectionの場合、新しいUUIDを発行する
+ 		gid, err := newUUIDFunc()
+ 		if err != nil {
+ 			return uuid.Nil, false, perrors.AsIs(err)
+ 		}
+ 		return gid, false, nil
+ 	}
+ 
+ 	// SingleSection の場合
+ 	if groupIndex == 0 {
+ 		// groupIndex が 0 の groupID には DefaultGroupID を割り振る
+ 		return DefaultGroupID, false, nil
+ 	} else {
+ 		// groupIndex が 0 でない場合は登録処理をスキップする
+ 		return uuid.Nil, true, nil
+ 	}
+ }
+ 
+ func (p csvInputIdentifierProvider) GetRowIndexByMemberIDAndIdentifier(memberID domain.MemberID, identifier CSVInputIdentifier) (domainCsv.RowIndex, error) {
+ 	rowIndexByIdentifier, ok := p.rowIndexByMemberIDAndIdentifier[memberID]
+ 	if !ok {
+ 		return domainCsv.RowIndex(0), perrors.Internalf("rowIndex not found for memberID: %v", memberID)
+ 	}
+ 
+ 	rowIndex, ok := rowIndexByIdentifier[identifier]
+ 	if !ok {
+ 		return domainCsv.RowIndex(0), perrors.Internalf("rowIndex not found for identifier: %v", identifier)
+ 	}
+ 
+ 	return rowIndex, nil
+ }
```

## apps/persia/app/domain/procedureform/csv_member.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ )
+ 
+ type RowWithMember struct {
+ 	Member domain.Member
+ 	Row    domainCsv.Row
+ }
+ 
+ type RowWithMemberList []RowWithMember
+ 
+ // 同一従業員の Row をまとめるためのメソッド
+ func (rs RowWithMemberList) ByMember() RowsByMember {
+ 	rowsByMember := make(RowsByMember, len(rs))
+ 	for _, rowWithMember := range rs {
+ 		memberID := domain.MemberID(rowWithMember.Member.ID)
+ 		if _, exists := rowsByMember[memberID]; !exists {
+ 			rowsByMember[memberID] = domainCsv.Rows{}
+ 		}
+ 		rowsByMember[memberID] = append(rowsByMember[memberID], rowWithMember.Row)
+ 	}
+ 	return rowsByMember
+ }
+ 
+ // RowsByMember は、従業員IDをキーとして、各従業員の行(複数) を格納するマップ
+ type RowsByMember map[domain.MemberID]domainCsv.Rows
+ 
+ func (rs RowsByMember) MemberIDs() domain.MemberIDs {
+ 	memberIDs := make(domain.MemberIDs, 0, len(rs))
+ 	for memberID := range rs {
+ 		memberIDs = append(memberIDs, memberID.String())
+ 	}
+ 	return memberIDs
+ }
+ 
+ func (rs RowsByMember) FilterByMemberIDs(memberIDs domain.MemberIDs) RowsByMember {
+ 	filteredRowsByMember := make(RowsByMember, len(memberIDs))
+ 	for _, memberID := range memberIDs {
+ 		rows, exists := rs[domain.MemberID(memberID)]
+ 		if !exists {
+ 			continue
+ 		}
+ 		filteredRowsByMember[domain.MemberID(memberID)] = rows
+ 	}
+ 	return filteredRowsByMember
+ }
+ 
+ // CheckEmployeeRowContinuity は、各従業員の行が連続しているかを確認する
+ func (rs RowsByMember) CheckEmployeeRowContinuity() error {
+ 	for _, rows := range rs {
+ 		if len(rows) < 2 {
+ 			// 1行以下は連続性のチェックをする必要がない
+ 			continue
+ 		}
+ 		var lastRowIndex domainCsv.RowIndex
+ 		for i, row := range rows {
+ 			if i == 0 {
+ 				lastRowIndex = row.Index
+ 				continue
+ 			}
+ 			currentRowIndex := row.Index
+ 			if currentRowIndex != lastRowIndex+1 {
+ 				rowNumber := int(currentRowIndex.ToNumber())
+ 				return NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 					{
+ 						RowNumber: &rowNumber,
+ 						ErrorType: domain.ProcedureCSVErrorTypeDuplicateMember,
+ 					},
+ 				})
+ 			}
+ 			lastRowIndex = currentRowIndex
+ 		}
+ 	}
+ 	return nil
+ }
+ 
+ // ToRowsWithMember は 引数の rowWithMemberList の順で RowsByMember を RowsWithMemberList に変換する
+ func (rs RowsByMember) ToRowsWithMember(rowWithMemberList RowWithMemberList) RowsWithMemberList {
+ 	res := make(RowsWithMemberList, 0, len(rs))
+ 	for _, rowWithMember := range rowWithMemberList {
+ 		rows, exists := rs[domain.MemberID(rowWithMember.Member.ID)]
+ 		if !exists {
+ 			continue
+ 		}
+ 		res = append(res, RowsWithMember{
+ 			Member: rowWithMember.Member,
+ 			Rows:   rows,
+ 		})
+ 	}
+ 	return res
+ }
+ 
+ type RowsWithMemberList []RowsWithMember
+ 
+ type RowsWithMember struct {
+ 	Member domain.Member
+ 	Rows   domainCsv.Rows
+ }
```

## apps/persia/app/domain/procedureform/csv_member_detector.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ // CSVMemberDetector は CSVの各行から従業員する特定するためのIF
+ type CSVMemberDetector interface {
+ 	DetectMemberByRow(row domainCsv.Row) (domain.Member, error)
+ }
+ 
+ type csvMemberDetectKey struct {
+ 	emailAddress   string
+ 	employeeNumber string
+ }
+ 
+ type csvMemberDetector struct {
+ 	membersByDetectKey        map[csvMemberDetectKey]domain.Member
+ 	emailAddressColumnIndex   domainCsv.ColumnIndex
+ 	employeeNumberColumnIndex domainCsv.ColumnIndex
+ }
+ 
+ func (md csvMemberDetector) DetectMemberByRow(row domainCsv.Row) (domain.Member, error) {
+ 	emailAddress, err := row.GetCell(md.emailAddressColumnIndex)
+ 	if err != nil {
+ 		return domain.Member{}, perrors.AsIs(err)
+ 	}
+ 
+ 	employeeNumber, err := row.GetCell(md.employeeNumberColumnIndex)
+ 	if err != nil {
+ 		return domain.Member{}, perrors.AsIs(err)
+ 	}
+ 
+ 	if emailAddress.Value == "" && employeeNumber.Value == "" {
+ 		rowNumber := int(row.Index.ToNumber())
+ 		return domain.Member{}, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{
+ 				RowNumber: &rowNumber,
+ 				ErrorType: domain.ProcedureCSVErrorTypeEmptyEmployeeNumberAndMailAddress,
+ 			},
+ 		})
+ 	}
+ 
+ 	detectKey := csvMemberDetectKey{
+ 		emailAddress:   emailAddress.Value,
+ 		employeeNumber: employeeNumber.Value,
+ 	}
+ 
+ 	member, ok := md.membersByDetectKey[detectKey]
+ 	if !ok {
+ 		rowNumber := int(row.Index.ToNumber())
+ 		// メールアドレスか従業員番号に誤りがある場合などに到達する
+ 		return domain.Member{}, NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{
+ 				RowNumber: &rowNumber,
+ 				ErrorType: domain.ProcedureCSVErrorTypeInvalidMember,
+ 			},
+ 		})
+ 	}
+ 
+ 	return member, nil
+ }
```

## apps/persia/app/domain/procedureform/csv_member_detector_test.go
```diff
+ package procedureform
+ 
+ import (
+ 	"testing"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors/codes"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/testutils"
+ 	"github.com/stretchr/testify/assert"
+ )
+ 
+ func TestCSVMemberDetector_DetectMemberByRow(t *testing.T) {
+ 	memberKey_normal := csvMemberDetectKey{
+ 		emailAddress:   "test1@example.com",
+ 		employeeNumber: "001",
+ 	}
+ 	member_normal := domain.Member{
+ 		ID:             "6fd5505f-7cb0-47ef-9339-2e52e3094ee0",
+ 		Email:          memberKey_normal.emailAddress,
+ 		EmployeeNumber: memberKey_normal.employeeNumber,
+ 		Name:           "member1",
+ 	}
+ 
+ 	// no email
+ 	memberKey_noEmail := csvMemberDetectKey{
+ 		emailAddress:   "",
+ 		employeeNumber: "002",
+ 	}
+ 	member_noEmail := domain.Member{
+ 		ID:             "08e6eefa-3027-437e-9340-453c1ef3afac",
+ 		Email:          memberKey_noEmail.emailAddress,
+ 		EmployeeNumber: memberKey_noEmail.employeeNumber,
+ 		Name:           "member2",
+ 	}
+ 
+ 	// no employeeNumber
+ 	memberKey_noEmployeeNumber := csvMemberDetectKey{
+ 		emailAddress:   "test3@example.com",
+ 		employeeNumber: "",
+ 	}
+ 	member_noEmployeeNumber := domain.Member{
+ 		ID:             "ae41ab04-f4ec-4309-a973-ba20491c3d00",
+ 		Email:          memberKey_noEmployeeNumber.emailAddress,
+ 		EmployeeNumber: memberKey_noEmployeeNumber.employeeNumber,
+ 		Name:           "member3",
+ 	}
+ 
+ 	membersByDetectKey := map[csvMemberDetectKey]domain.Member{
+ 		memberKey_normal:           member_normal,
+ 		memberKey_noEmail:          member_noEmail,
+ 		memberKey_noEmployeeNumber: member_noEmployeeNumber,
+ 	}
+ 
+ 	tests := []struct {
+ 		name         string
+ 		detector     csvMemberDetector
+ 		row          domainCsv.Row
+ 		want         domain.Member
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name: "success: member found by email and employee number",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey:        membersByDetectKey,
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_normal.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_normal.employeeNumber},
+ 				},
+ 			},
+ 			want:         member_normal,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: member found with empty employee number",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey:        membersByDetectKey,
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_noEmail.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_noEmail.employeeNumber},
+ 				},
+ 			},
+ 			want:         member_noEmail,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: member found with empty email address",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey:        membersByDetectKey,
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_noEmployeeNumber.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_noEmployeeNumber.employeeNumber},
+ 				},
+ 			},
+ 			want:         member_noEmployeeNumber,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "error: member not found",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey: map[csvMemberDetectKey]domain.Member{
+ 					memberKey_noEmail: member_noEmail,
+ 				},
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_normal.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_normal.employeeNumber},
+ 				},
+ 			},
+ 			want: domain.Member{},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(1),
+ 					ErrorType: domain.ProcedureCSVErrorTypeInvalidMember,
+ 				},
+ 			})),
+ 		},
+ 		{
+ 			name: "error: email address column index is out of range",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey: map[csvMemberDetectKey]domain.Member{
+ 					memberKey_normal: member_normal,
+ 				},
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 5, // out of range
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_normal.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_normal.employeeNumber},
+ 				},
+ 			},
+ 			want:         domain.Member{},
+ 			errAssertion: testutils.AssertErrorCode(codes.Internal),
+ 		},
+ 		{
+ 			name: "error: employee number column index is out of range",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey: map[csvMemberDetectKey]domain.Member{
+ 					memberKey_normal: member_normal,
+ 				},
+ 				emailAddressColumnIndex:   5, // out of range
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_normal.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_normal.employeeNumber},
+ 				},
+ 			},
+ 			want:         domain.Member{},
+ 			errAssertion: testutils.AssertErrorCode(codes.Internal),
+ 		},
+ 		{
+ 			name: "error: invalid email address column index",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey: map[csvMemberDetectKey]domain.Member{
+ 					memberKey_normal: member_normal,
+ 				},
+ 				emailAddressColumnIndex:   2, // invalid index
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_normal.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_normal.employeeNumber},
+ 					{ColumnIndex: 2, RowIndex: 0, Value: member_normal.Name},
+ 				},
+ 			},
+ 			want: domain.Member{},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(1),
+ 					ErrorType: domain.ProcedureCSVErrorTypeInvalidMember,
+ 				},
+ 			})),
+ 		},
+ 		{
+ 			name: "error: invalid employee number column index",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey: map[csvMemberDetectKey]domain.Member{
+ 					memberKey_normal: member_normal,
+ 				},
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 2, // invalid index
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: memberKey_normal.emailAddress},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: memberKey_normal.employeeNumber},
+ 					{ColumnIndex: 2, RowIndex: 0, Value: member_normal.Name},
+ 				},
+ 			},
+ 			want: domain.Member{},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(1),
+ 					ErrorType: domain.ProcedureCSVErrorTypeInvalidMember,
+ 				},
+ 			})),
+ 		},
+ 		{
+ 			name: "error: employee number and email address are both empty",
+ 			detector: csvMemberDetector{
+ 				membersByDetectKey: map[csvMemberDetectKey]domain.Member{
+ 					memberKey_normal: member_normal,
+ 				},
+ 				emailAddressColumnIndex:   0,
+ 				employeeNumberColumnIndex: 1,
+ 			},
+ 			row: domainCsv.Row{
+ 				Index: 0,
+ 				Cells: []domainCsv.Cell{
+ 					{ColumnIndex: 0, RowIndex: 0, Value: ""},
+ 					{ColumnIndex: 1, RowIndex: 0, Value: ""},
+ 				},
+ 			},
+ 			want: domain.Member{},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(1),
+ 					ErrorType: domain.ProcedureCSVErrorTypeEmptyEmployeeNumberAndMailAddress,
+ 				},
+ 			})),
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got, err := tt.detector.DetectMemberByRow(tt.row)
+ 			tt.errAssertion(t, err)
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
```

## apps/persia/app/domain/procedureform/csv_member_test.go
```diff
+ package procedureform
+ 
+ import (
+ 	"testing"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/testutils"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/util"
+ 	"github.com/stretchr/testify/assert"
+ )
+ 
+ func TestRowsWithMember_ByMember(t *testing.T) {
+ 	memberID1 := util.NewFixedUUID("29a74fcf-f8b1-4f81-beae-2fd056a2e3f3")
+ 	memberID2 := util.NewFixedUUID("788b8ace-1267-407b-a420-64fd977be8e3")
+ 	tests := []struct {
+ 		name string
+ 		rows RowWithMemberList
+ 		want RowsByMember
+ 	}{
+ 		{
+ 			name: "success: single member with single row",
+ 			rows: RowWithMemberList{
+ 				{
+ 					Member: domain.Member{ID: memberID1.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "success: single member with multiple rows",
+ 			rows: RowWithMemberList{
+ 				{
+ 					Member: domain.Member{ID: memberID1.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				{
+ 					Member: domain.Member{ID: memberID1.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "success: multiple members with single row each",
+ 			rows: RowWithMemberList{
+ 				{
+ 					Member: domain.Member{ID: memberID1.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				{
+ 					Member: domain.Member{ID: memberID2.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "success: multiple members with multiple rows",
+ 			rows: RowWithMemberList{
+ 				{
+ 					Member: domain.Member{ID: memberID1.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				{
+ 					Member: domain.Member{ID: memberID2.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 				{
+ 					Member: domain.Member{ID: memberID1.String()},
+ 					Row: domainCsv.Row{
+ 						Index: 2,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 2, Value: "value3"}},
+ 					},
+ 				},
+ 			},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 					{
+ 						Index: 2,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 2, Value: "value3"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "success: empty rows",
+ 			rows: RowWithMemberList{},
+ 			want: RowsByMember{},
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got := tt.rows.ByMember()
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
+ 
+ func TestRowsByMember_MemberIDs(t *testing.T) {
+ 	memberID1 := util.NewFixedUUID("29a74fcf-f8b1-4f81-beae-2fd056a2e3f3")
+ 	memberID2 := util.NewFixedUUID("788b8ace-1267-407b-a420-64fd977be8e3")
+ 	tests := []struct {
+ 		name string
+ 		rows RowsByMember
+ 		want domain.MemberIDs
+ 	}{
+ 		{
+ 			name: "success: single member",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 			want: domain.MemberIDs{memberID1.String()},
+ 		},
+ 		{
+ 			name: "success: multiple members",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 			want: domain.MemberIDs{memberID1.String(), memberID2.String()},
+ 		},
+ 		{
+ 			name: "success: empty rows",
+ 			rows: RowsByMember{},
+ 			want: domain.MemberIDs{},
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got := tt.rows.MemberIDs()
+ 			assert.ElementsMatch(t, tt.want, got)
+ 		})
+ 	}
+ }
+ 
+ func TestRowsByMember_FilterByMemberIDs(t *testing.T) {
+ 	memberID1 := util.NewFixedUUID("29a74fcf-f8b1-4f81-beae-2fd056a2e3f3")
+ 	memberID2 := util.NewFixedUUID("788b8ace-1267-407b-a420-64fd977be8e3")
+ 	memberID3 := util.NewFixedUUID("f0568b6d-02c2-4156-baf3-d7915a8201d2")
+ 	tests := []struct {
+ 		name      string
+ 		rows      RowsByMember
+ 		memberIDs domain.MemberIDs
+ 		want      RowsByMember
+ 	}{
+ 		{
+ 			name: "filter single member",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 			memberIDs: domain.MemberIDs{memberID1.String()},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "filter multiple members",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID3.String()): domainCsv.Rows{
+ 					{
+ 						Index: 2,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 2, Value: "value3"}},
+ 					},
+ 				},
+ 			},
+ 			memberIDs: domain.MemberIDs{memberID1.String(), memberID2.String()},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "filter all members",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 			memberIDs: domain.MemberIDs{memberID1.String(), memberID2.String()},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name: "empty memberIDs",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 			memberIDs: domain.MemberIDs{},
+ 			want:      RowsByMember{},
+ 		},
+ 		{
+ 			name: "memberID not found",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 			memberIDs: domain.MemberIDs{memberID2.String()},
+ 			want:      RowsByMember{},
+ 		},
+ 		{
+ 			name: "some memberIDs not found",
+ 			rows: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 			memberIDs: domain.MemberIDs{memberID1.String(), memberID2.String()},
+ 			want: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 			},
+ 		},
+ 		{
+ 			name:      "empty rows with empty memberIDs",
+ 			rows:      RowsByMember{},
+ 			memberIDs: domain.MemberIDs{},
+ 			want:      RowsByMember{},
+ 		},
+ 		{
+ 			name:      "empty rows with non-empty memberIDs",
+ 			rows:      RowsByMember{},
+ 			memberIDs: domain.MemberIDs{memberID1.String()},
+ 			want:      RowsByMember{},
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got := tt.rows.FilterByMemberIDs(tt.memberIDs)
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
+ 
+ func TestRowsByMember_CheckEmployeeRowContinuity(t *testing.T) {
+ 	memberID1 := util.NewFixedUUID("29a74fcf-f8b1-4f81-beae-2fd056a2e3f3")
+ 	memberID2 := util.NewFixedUUID("788b8ace-1267-407b-a420-64fd977be8e3")
+ 	tests := []struct {
+ 		name         string
+ 		rs           RowsByMember
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name:         "success: empty rows",
+ 			rs:           RowsByMember{},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: single row per member",
+ 			rs: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: continuous rows for member",
+ 			rs: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 					{
+ 						Index: 2,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 2, Value: "value3"}},
+ 					},
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: multiple members with continuous rows",
+ 			rs: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 5,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 5, Value: "value6"}},
+ 					},
+ 					{
+ 						Index: 6,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 6, Value: "value7"}},
+ 					},
+ 					{
+ 						Index: 7,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 7, Value: "value8"}},
+ 					},
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "error: non-continuous rows for member",
+ 			rs: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 					{
+ 						Index: 2, // Skip index 1, should cause error
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 2, Value: "value3"}},
+ 					},
+ 				},
+ 			},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(3),
+ 					ErrorType: domain.ProcedureCSVErrorTypeDuplicateMember,
+ 				},
+ 			})),
+ 		},
+ 		{
+ 			name: "error: non-continuous rows in the middle",
+ 			rs: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 2,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 2, Value: "value3"}},
+ 					},
+ 					{
+ 						Index: 3,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 3, Value: "value4"}},
+ 					},
+ 					{
+ 						Index: 5, // Skip index 4, should cause error
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 5, Value: "value6"}},
+ 					},
+ 				},
+ 			},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(6),
+ 					ErrorType: domain.ProcedureCSVErrorTypeDuplicateMember,
+ 				},
+ 			})),
+ 		},
+ 		{
+ 			name: "error: one member has continuous rows, another has non-continuous",
+ 			rs: RowsByMember{
+ 				domain.MemberID(memberID1.String()): domainCsv.Rows{
+ 					{
+ 						Index: 0,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 0, Value: "value1"}},
+ 					},
+ 					{
+ 						Index: 1,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 1, Value: "value2"}},
+ 					},
+ 				},
+ 				domain.MemberID(memberID2.String()): domainCsv.Rows{
+ 					{
+ 						Index: 3,
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 3, Value: "value4"}},
+ 					},
+ 					{
+ 						Index: 5, // Skip index 4, should cause error
+ 						Cells: []domainCsv.Cell{{ColumnIndex: 0, RowIndex: 5, Value: "value6"}},
+ 					},
+ 				},
+ 			},
+ 			errAssertion: testutils.AssertErrorAs(NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 				{
+ 					RowNumber: testutils.ToPtr(6),
+ 					ErrorType: domain.ProcedureCSVErrorTypeDuplicateMember,
+ 				},
+ 			})),
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			err := tt.rs.CheckEmployeeRowContinuity()
+ 			tt.errAssertion(t, err)
+ 		})
+ 	}
+ }
```

## apps/persia/app/domain/procedureform/csv_normalize.go
```diff
+ package procedureform
+ 
+ import (
+ 	"strconv"
+ 	"strings"
+ 	"time"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ // normalizeCSVInputIntegerは、Integer型のCSV値を正規化する処理
+ func normalizeCSVInputInteger(csvValue string) (string, error) {
+ 	if csvValue == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// Excelで数値を編集したときにスペースが入り込むことがあるので取り除く
+ 	trimmedValue := strings.TrimSpace(csvValue)
+ 	// カンマを取り除く
+ 	sanitizedNumberStr := strings.ReplaceAll(trimmedValue, ",", "")
+ 	return sanitizedNumberStr, nil
+ }
+ 
+ // normalizeCSVInputFloatは、Float型のCSV値を正規化する処理
+ func normalizeCSVInputFloat(csvValue string) (string, error) {
+ 	if csvValue == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// Excelで数値を編集したときにスペースが入り込むことがあるので取り除く
+ 	trimmedValue := strings.TrimSpace(csvValue)
+ 	// カンマを取り除く
+ 	sanitizedNumberStr := strings.ReplaceAll(trimmedValue, ",", "")
+ 	return sanitizedNumberStr, nil
+ }
+ 
+ // normalizeCSVInputSingleSelectionは、SingleSelection型のCSV値を正規化する処理
+ func normalizeCSVInputSingleSelection(input Input, csvValue string) (string, error) {
+ 	return normalizeCSVInputSelectionInput(input, csvValue)
+ }
+ 
+ // normalizeCSVInputToggleは、Toggle型のCSV値を正規化する処理
+ func normalizeCSVInputToggle(input Input, csvValue string) (string, error) {
+ 	return normalizeCSVInputSelectionInput(input, csvValue)
+ }
+ 
+ // normalizeCSVInputSelectionInput は、SelectionInputとToggle型のDB値をCSV出力用に変換する処理
+ func normalizeCSVInputSelectionInput(input Input, csvValue string) (string, error) {
+ 	if csvValue == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// csvに入っている値が選択肢のラベルの場合、DBに保存する Value に変換する
+ 	value, found := input.SelectionOptions.LabelToValue(csvValue)
+ 	if found {
+ 		return value, nil
+ 	}
+ 
+ 	// csvに入っている値が選択肢のラベルでなかった場合、オーダーが入力されているとみなし、Valueへの変換を試みる
+ 	num, err := strconv.ParseUint(csvValue, 10, 16)
+ 	if err != nil {
+ 		return "", perrors.BadRequestf("failed to convert csvValue to uint16")
+ 	}
+ 
+ 	value, found = input.SelectionOptions.OrderToValue(uint16(num))
+ 	if found {
+ 		return value, nil
+ 	}
+ 
+ 	// csvに入っている値が選択肢のラベルでもオーダーでもなかった場合は変換できなかったとしてエラーにする
+ 	return "", NewCSVUploadDataError(domain.CSVUploadDataErrorsToSaveV2{
+ 		{
+ 			ErrorType: domain.ProcedureCSVErrorTypeValueIsNotInOption,
+ 		},
+ 	})
+ }
+ 
+ // normalizeCSVInputLargeToggleは、LargeToggle型のCSV値を正規化する処理
+ func normalizeCSVInputLargeToggle(input Input, csvValue string) (string, error) {
+ 	if csvValue == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// csvに入っている値が選択肢のラベルの場合、DBに保存する Value に変換する
+ 	value, found := input.LargeToggleOptions.LabelToValue(csvValue)
+ 	if found {
+ 		return value, nil
+ 	}
+ 
+ 	// csvに入っている値が選択肢のラベルでなかった場合、オーダーが入力されているとみなし、Valueへの変換を試みる
+ 	num, err := strconv.ParseUint(csvValue, 10, 8)
+ 	if err != nil {
+ 		return "", perrors.BadRequestf("failed to convert csvValue to uint8")
+ 	}
+ 
+ 	value, found = input.LargeToggleOptions.OrderToValue(uint8(num))
+ 	if found {
+ 		return value, nil
+ 	}
+ 
+ 	// csvに入っている値が選択肢のラベルでもオーダーでもなかった場合は変換できなかったとしてエラーにする
+ 	return "", NewCSVUploadDataError(domain.CSVUploadDataErrorsToSaveV2{
+ 		{
+ 			ErrorType: domain.ProcedureCSVErrorTypeValueIsNotInOption,
+ 		},
+ 	})
+ }
+ 
+ // normalizeCSVInputDateは、Date型のCSV値を正規化する処理
+ func normalizeCSVInputDate(csvValue string) (string, error) {
+ 	if csvValue == "" {
+ 		return "", nil // 空文字列はそのまま返す
+ 	}
+ 	// 日付がスラッシュ区切りで入力されていても読み込めるように、ハイフン区切りに変換する
+ 	replacedValue := strings.ReplaceAll(csvValue, "/", "-")
+ 	_, err := time.Parse(DateFormat, replacedValue)
+ 	if err != nil {
+ 		return "", NewCSVUploadDataError(domain.CSVUploadDataErrorsToSaveV2{
+ 			{
+ 				ErrorType: domain.ProcedureCSVErrorTypeCannotConvertToDate,
+ 			},
+ 		})
+ 	}
+ 	return replacedValue, nil
+ }
```

## apps/persia/app/domain/procedureform/form_values_input_value.go
```diff
+ // 入力値を DateRange に変換する。
+ //
+ // 第一返り値: 変換結果, 第二返り値: 変換に成功したか (空の場合は false), 第三返り値: 入力されている場合の変換エラー
+ func (iv InputValue) ParseDateRange() (DateRange, bool, error) {
+ 	v, ok, err := getCacheOrParseInputValue(iv, inputValueDateRangeParser)
+ 	return v, ok, perrors.AsIs(err)
+ }
+ 
+ // 入力値を日付のみの DateRange に変換する。
+ //
+ // 第一返り値: 変換結果, 第二返り値: 変換に成功したか (入力値が空ではなく、変換エラーも発生しなかった場合)
+ func (iv InputValue) ToDateRange() (DateRange, bool) {
+ 	return getCacheOrConvertInputValue(iv, inputValueDateRangeParser)
+ }
+ 
```

## apps/persia/app/domain/procedureform/form_values_input_value_test.go
```diff
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/testutils"
+ func TestInputValue_ParseDateRange_ToDateRange(t *testing.T) {
+ 	type fields struct {
+ 		rawValue string
+ 	}
+ 	tests := []struct {
+ 		name      string
+ 		fields    fields
+ 		want      procedureform.DateRange
+ 		want1     bool
+ 		assertion require.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name: "success - empty string",
+ 			fields: fields{
+ 				rawValue: "",
+ 			},
+ 			want:      procedureform.DateRange{},
+ 			want1:     false,
+ 			assertion: require.NoError,
+ 		},
+ 		{
+ 			name: "success - empty (json)",
+ 			fields: fields{
+ 				rawValue: `{}`,
+ 			},
+ 			want: procedureform.DateRange{
+ 				Start: nil,
+ 				End:   nil,
+ 			},
+ 			want1:     true,
+ 			assertion: require.NoError,
+ 		},
+ 		{
+ 			name: "success - not empty (start and end)",
+ 			fields: fields{
+ 				rawValue: `{"start":"2025-01-01","end":"2025-01-10"}`,
+ 			},
+ 			want: procedureform.DateRange{
+ 				Start: testutils.ToPtr(time.Date(2025, 1, 1, 0, 0, 0, 0, times.LocationTokyo)),
+ 				End:   testutils.ToPtr(time.Date(2025, 1, 10, 0, 0, 0, 0, times.LocationTokyo)),
+ 			},
+ 			want1:     true,
+ 			assertion: require.NoError,
+ 		},
+ 		{
+ 			name: "success - not empty (start only)",
+ 			fields: fields{
+ 				rawValue: `{"start":"2025-01-01"}`,
+ 			},
+ 			want: procedureform.DateRange{
+ 				Start: testutils.ToPtr(time.Date(2025, 1, 1, 0, 0, 0, 0, times.LocationTokyo)),
+ 				End:   nil,
+ 			},
+ 			want1:     true,
+ 			assertion: require.NoError,
+ 		},
+ 		{
+ 			name: "success - not empty (end only)",
+ 			fields: fields{
+ 				rawValue: `{"end":"2025-01-10"}`,
+ 			},
+ 			want: procedureform.DateRange{
+ 				Start: nil,
+ 				End:   testutils.ToPtr(time.Date(2025, 1, 10, 0, 0, 0, 0, times.LocationTokyo)),
+ 			},
+ 			want1:     true,
+ 			assertion: require.NoError,
+ 		},
+ 		{
+ 			name: "fail - invalid format",
+ 			fields: fields{
+ 				rawValue: "{test}",
+ 			},
+ 			want:      procedureform.DateRange{},
+ 			want1:     false,
+ 			assertion: require.Error,
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			iv := procedureform.NewInputValue(tt.fields.rawValue)
+ 			got, got1, err := iv.ParseDateRange()
+ 			tt.assertion(t, err)
+ 			assert.Equal(t, tt.want, got)
+ 			assert.Equal(t, tt.want1, got1)
+ 
+ 			got2, got3 := iv.ToDateRange()
+ 			assert.Equal(t, tt.want, got2)
+ 			assert.Equal(t, tt.want1, got3)
+ 		})
+ 	}
+ }
+ 
```

## apps/persia/app/domain/procedureform/form_values_input_value_types.go
```diff
+ /* DateRange */
+ 
+ var inputValueDateRangeParser = func(rawValue string) (DateRange, error) {
+ 	dr := DateRange{}
+ 	err := dr.UnmarshalJSON([]byte(rawValue))
+ 	if err != nil {
+ 		return DateRange{}, perrors.BadRequest(err)
+ 	}
+ 	return dr, nil
+ }
+ 
+ // DateRange を JSON 文字列に変換し、InputValue を作成する
+ func NewInputValueFromDateRange(value DateRange) (InputValue, error) {
+ 	data, err := value.MarshalJSON()
+ 	if err != nil {
+ 		return InputValue{}, perrors.Internal(err)
+ 	}
+ 	return newInputValueWithCache(string(data), value), nil
+ }
+ 
```

## apps/persia/app/domain/procedureform/form_values_input_value_types_test.go
```diff
+ func Test_inputValueDateRangeParser(t *testing.T) {
+ 	tests := []struct {
+ 		name         string
+ 		rawValue     string
+ 		expected     DateRange
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name:     "success: valid JSON",
+ 			rawValue: `{"start":"2025-06-01","end":"2025-06-30"}`,
+ 			expected: DateRange{
+ 				Start: testutils.ToPtr(time.Date(2025, 6, 1, 0, 0, 0, 0, times.LocationTokyo)),
+ 				End:   testutils.ToPtr(time.Date(2025, 6, 30, 0, 0, 0, 0, times.LocationTokyo)),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:     "success: empty JSON",
+ 			rawValue: `{}`,
+ 			expected: DateRange{
+ 				Start: nil,
+ 				End:   nil,
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:         "success: empty string",
+ 			rawValue:     "",
+ 			expected:     DateRange{},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:         "error: invalid JSON",
+ 			rawValue:     `{"start":"2025-06-01","end":}`,
+ 			expected:     DateRange{},
+ 			errAssertion: testutils.AssertErrorCode(codes.BadRequest),
+ 		},
+ 		{
+ 			name:         "error: not JSON",
+ 			rawValue:     "test",
+ 			expected:     DateRange{},
+ 			errAssertion: testutils.AssertErrorCode(codes.BadRequest),
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got, err := inputValueDateRangeParser(tt.rawValue)
+ 			tt.errAssertion(t, err)
+ 			assert.Equal(t, tt.expected, got)
+ 		})
+ 	}
+ }
+ 
+ func TestNewInputValueFromDateRange(t *testing.T) {
+ 	tests := []struct {
+ 		name         string
+ 		dateRange    DateRange
+ 		want         string
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name: "success: with start and end",
+ 			dateRange: DateRange{
+ 				Start: testutils.ToPtr(time.Date(2025, 6, 1, 0, 0, 0, 0, times.LocationTokyo)),
+ 				End:   testutils.ToPtr(time.Date(2025, 6, 30, 0, 0, 0, 0, times.LocationTokyo)),
+ 			},
+ 			want:         `{"start":"2025-06-01","end":"2025-06-30"}`,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: start only",
+ 			dateRange: DateRange{
+ 				Start: testutils.ToPtr(time.Date(2025, 6, 1, 0, 0, 0, 0, times.LocationTokyo)),
+ 			},
+ 			want:         `{"start":"2025-06-01"}`,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: end only",
+ 			dateRange: DateRange{
+ 				End: testutils.ToPtr(time.Date(2025, 6, 30, 0, 0, 0, 0, times.LocationTokyo)),
+ 			},
+ 			want:         `{"end":"2025-06-30"}`,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:         "success: empty values",
+ 			dateRange:    DateRange{},
+ 			want:         `{}`,
+ 			errAssertion: assert.NoError,
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			result, err := NewInputValueFromDateRange(tt.dateRange)
+ 			tt.errAssertion(t, err)
+ 			assert.Equal(t, tt.want, result.rawValue)
+ 
+ 			// JSONとして正しくパースできることを確認
+ 			var parsed DateRange
+ 			err = json.Unmarshal([]byte(result.rawValue), &parsed)
+ 			require.NoError(t, err)
+ 			assert.Equal(t, tt.dateRange, parsed)
+ 		})
+ 	}
+ }
+ 
```

## apps/persia/app/domain/procedureform/form_values_unit_values.go
```diff
+ package procedureform
+ 
+ import (
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ )
+ 
+ func NewFormValuesFromMemberUnitValues(inputIDByUnitID map[domain.MembersFixedUnitID]InputID, unitValues domain.MemberUnitStringValues) (FormValues, error) {
+ 	builder := NewFormValuesBuilder()
+ 
+ 	for unitID, value := range unitValues.UnitValues {
+ 		inputID, exists := inputIDByUnitID[unitID]
+ 		if !exists {
+ 			return FormValues{}, perrors.Internalf("inputIDByUnitID has no key for :%s", unitID)
+ 		}
+ 
+ 		builder.AddInputValue(inputID).String(value)
+ 	}
+ 
+ 	for _, blockedUnitValues := range unitValues.BlockedUnitValues {
+ 		groupID := blockedUnitValues.BlockID
+ 		groupedBuilder := builder.NewGroupWithID(groupID)
+ 		for unitID, value := range blockedUnitValues.UnitValues {
+ 			inputID, exists := inputIDByUnitID[unitID]
+ 			if !exists {
+ 				return FormValues{}, perrors.Internalf("inputIDByUnitID has no key for :%s", unitID)
+ 			}
+ 
+ 			groupedBuilder.AddInputValue(inputID).String(value)
+ 		}
+ 		groupedBuilder.AppendGroup()
+ 	}
+ 
+ 	return builder.Build(), nil
+ }
```

## apps/persia/app/domain/procedureform/form_values_unit_values_test.go
```diff
+ package procedureform
+ 
+ import (
+ 	"testing"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors/codes"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/testutils"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/util"
+ 	"github.com/stretchr/testify/assert"
+ )
+ 
+ func TestNewFormValuesFromMemberUnitValues(t *testing.T) {
+ 	inputID1 := util.NewFixedUUID("c39b9d49-dfcd-45ac-8d80-33a4dc5786b1")
+ 	inputID2 := util.NewFixedUUID("65c1eaf4-720e-4288-8892-3b04fcb222d2")
+ 	inputID3 := util.NewFixedUUID("4b9b46ba-c315-4989-aef5-7db805ec71ba")
+ 	inputID4 := util.NewFixedUUID("fd90c192-b0f9-4525-a321-deb8d05caf9d")
+ 
+ 	unitID1 := domain.MembersFixedUnitID("168b1204-749d-453d-b2a0-b94d5c5de6f2")
+ 	unitID2 := domain.MembersFixedUnitID("b30d3030-1dd7-493a-8c5e-6adcae92ef4c")
+ 	unitID3 := domain.MembersFixedUnitID("2116768d-0bdc-425c-85fb-4215c91dd414")
+ 	unitID4 := domain.MembersFixedUnitID("2853cdb4-2ab4-45d3-9edc-46a3c46c484b")
+ 
+ 	blockID1 := util.NewFixedUUID("68c08e10-a583-4156-8a8a-104e62633fc7")
+ 	blockID2 := util.NewFixedUUID("20dc3b4b-a382-4e7b-bcff-69ca73dd2a06")
+ 
+ 	inputIDByUnitID := map[domain.MembersFixedUnitID]InputID{
+ 		unitID1: inputID1,
+ 		unitID2: inputID2,
+ 		unitID3: inputID3,
+ 		unitID4: inputID4,
+ 	}
+ 
+ 	type args struct {
+ 		inputIDByUnitID map[domain.MembersFixedUnitID]InputID
+ 		unitValues      domain.MemberUnitStringValues
+ 	}
+ 	tests := []struct {
+ 		name         string
+ 		args         args
+ 		want         FormValues
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name: "success: only unitValues",
+ 			args: args{
+ 				inputIDByUnitID: inputIDByUnitID,
+ 				unitValues: domain.MemberUnitStringValues{
+ 					UnitValues: domain.UnitStringValues{
+ 						unitID1: "value1",
+ 						unitID2: "value2",
+ 					},
+ 				},
+ 			},
+ 			want: NewFormValuesBuilder().
+ 				AddInputValue(inputID1).String("value1").
+ 				AddInputValue(inputID2).String("value2").Build(),
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: only blockedUnitValues",
+ 			args: args{
+ 				inputIDByUnitID: inputIDByUnitID,
+ 				unitValues: domain.MemberUnitStringValues{
+ 					BlockedUnitValues: []domain.BlockedUnitStringValues{
+ 						{
+ 							BlockID: blockID1,
+ 							UnitValues: domain.UnitStringValues{
+ 								unitID3: "value3-1",
+ 							},
+ 						},
+ 						{
+ 							BlockID: blockID2,
+ 							UnitValues: domain.UnitStringValues{
+ 								unitID3: "value3-2",
+ 								unitID4: "value4-2",
+ 							},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			want: NewFormValuesBuilder().
+ 				NewGroupWithID(blockID1).
+ 				AddInputValue(inputID3).String("value3-1").AppendGroup().
+ 				NewGroupWithID(blockID2).
+ 				AddInputValue(inputID3).String("value3-2").
+ 				AddInputValue(inputID4).String("value4-2").AppendGroup().
+ 				Build(),
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: unitValues and blockedUnitValues",
+ 			args: args{
+ 				inputIDByUnitID: inputIDByUnitID,
+ 				unitValues: domain.MemberUnitStringValues{
+ 					UnitValues: domain.UnitStringValues{
+ 						unitID1: "value1",
+ 						unitID2: "value2",
+ 					},
+ 					BlockedUnitValues: []domain.BlockedUnitStringValues{
+ 						{
+ 							BlockID: blockID1,
+ 							UnitValues: domain.UnitStringValues{
+ 								unitID3: "value3-1",
+ 							},
+ 						},
+ 						{
+ 							BlockID: blockID2,
+ 							UnitValues: domain.UnitStringValues{
+ 								unitID3: "value3-2",
+ 								unitID4: "value4-2",
+ 							},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			want: NewFormValuesBuilder().
+ 				AddInputValue(inputID1).String("value1").
+ 				AddInputValue(inputID2).String("value2").
+ 				NewGroupWithID(blockID1).
+ 				AddInputValue(inputID3).String("value3-1").AppendGroup().
+ 				NewGroupWithID(blockID2).
+ 				AddInputValue(inputID3).String("value3-2").
+ 				AddInputValue(inputID4).String("value4-2").AppendGroup().
+ 				Build(),
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: unitValues and blockedUnitValues are empty",
+ 			args: args{
+ 				inputIDByUnitID: inputIDByUnitID,
+ 				unitValues: domain.MemberUnitStringValues{
+ 					UnitValues:        domain.UnitStringValues{},
+ 					BlockedUnitValues: []domain.BlockedUnitStringValues{},
+ 				},
+ 			},
+ 			want:         NewEmptyFormValues(),
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "success: unitValues and blockedUnitValues are nil",
+ 			args: args{
+ 				inputIDByUnitID: inputIDByUnitID,
+ 				unitValues: domain.MemberUnitStringValues{
+ 					UnitValues:        nil,
+ 					BlockedUnitValues: nil,
+ 				},
+ 			},
+ 			want:         NewEmptyFormValues(),
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name: "failure: incomplete inputIDByUnitID (only UnitValues)",
+ 			args: args{
+ 				inputIDByUnitID: map[domain.MembersFixedUnitID]InputID{
+ 					unitID1: inputID1,
+ 				},
+ 				unitValues: domain.MemberUnitStringValues{
+ 					UnitValues: domain.UnitStringValues{
+ 						unitID1: "value1",
+ 						unitID2: "value2",
+ 					},
+ 					BlockedUnitValues: []domain.BlockedUnitStringValues{},
+ 				},
+ 			},
+ 			want:         FormValues{},
+ 			errAssertion: testutils.AssertErrorCode(codes.Internal),
+ 		},
+ 		{
+ 			name: "failure: incomplete inputIDByUnitID (only UnitValues)",
+ 			args: args{
+ 				inputIDByUnitID: map[domain.MembersFixedUnitID]InputID{
+ 					unitID3: inputID3,
+ 				},
+ 				unitValues: domain.MemberUnitStringValues{
+ 					UnitValues: domain.UnitStringValues{},
+ 					BlockedUnitValues: []domain.BlockedUnitStringValues{
+ 						{
+ 							BlockID: blockID1,
+ 							UnitValues: domain.UnitStringValues{
+ 								unitID3: "value3-1",
+ 							},
+ 						},
+ 						{
+ 							BlockID: blockID2,
+ 							UnitValues: domain.UnitStringValues{
+ 								unitID3: "value3-2",
+ 								unitID4: "value4-2",
+ 							},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			want:         FormValues{},
+ 			errAssertion: testutils.AssertErrorCode(codes.Internal),
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			got, err := NewFormValuesFromMemberUnitValues(tt.args.inputIDByUnitID, tt.args.unitValues)
+ 			tt.errAssertion(t, err)
+ 			assert.Equal(t, tt.want, got)
+ 		})
+ 	}
+ }
```

## apps/persia/app/domain/procedureform/types_form.go
```diff
+ func (f Form) GetInputIDsMap() map[InputID]Input {
+ 	res := make(map[uuid.UUID]Input)
+ 	for _, page := range f.Pages {
+ 		for _, section := range page.Sections {
+ 			for _, row := range section.Rows {
+ 				for _, input := range row.Inputs {
+ 					res[input.ID] = input
+ 				}
+ 			}
+ 		}
+ 	}
+ 
+ 	return res
+ }
+ 
+ func (f Form) GetSectionIDsMap() map[SectionID]Section {
+ 	res := make(map[SectionID]Section)
+ 	for _, page := range f.Pages {
+ 		for _, section := range page.Sections {
+ 			res[section.ID] = section
+ 		}
+ 	}
+ 
+ 	return res
+ }
+ 
+ func (f Form) GetSectionByInputID() map[InputID]Section {
+ 	res := make(map[InputID]Section)
+ 	for _, page := range f.Pages {
+ 		for _, section := range page.Sections {
+ 			for _, row := range section.Rows {
+ 				for _, input := range row.Inputs {
+ 					res[input.ID] = section
+ 				}
+ 			}
+ 		}
+ 	}
+ 
+ 	return res
+ }
+ 
```

## apps/persia/app/domain/procedureform/types_input.go
```diff
+ 	case InputTypeDateRange:
+ 		return input.validateDateRange(value, isDraft)
+ /*
+ start, endの入力チェックをし、「フォームの入力の仕方が正しいか」をチェックする
+ - start, endがどちらも埋まっている -> 必須・任意、下書き保存・本保存に関わらずok
+ - start, endのいずれかが埋まっている -> 必須・任意項目にかかわらず、下書き保存・本保存した時にerror
+ - start, endのどちらも埋まっていない -> 任意項目ならok, 必須項目は下書き保存の場合のみok
+ */
+ func (input Input) validateDateRange(value string, isDraft bool) (InputValidationResult, error) {
+ 	var dateRange DateRange
+ 
+ 	if err := dateRange.UnmarshalJSON([]byte(value)); err != nil {
+ 		// システム起因のエラーなので perrors.Internal を返す
+ 		return InputValidationResultInternalError, perrors.Internal(err)
+ 	}
+ 
+ 	// 時刻関係の逆転チェック
+ 	if err := dateRange.Validate(); err != nil {
+ 		//nolint:nilerr
+ 		return InputValidationResultInvalidFormat, nil
+ 	}
+ 
+ 	// フォーム入力としての正しさをチェック
+ 	// どちらか一方しか入っていない場合はエラー
+ 	if (dateRange.Start == nil && dateRange.End != nil) || (dateRange.Start != nil && dateRange.End == nil) {
+ 		return InputValidationResultInvalidFormat, nil
+ 	}
+ 
+ 	// 必須項目かつ本保存時の場合のみ、両方が空であることをチェック
+ 	if input.Validation.Required && !isDraft {
+ 		if dateRange.Start == nil || dateRange.End == nil {
+ 			return InputValidationResultRequired, nil
+ 		}
+ 	}
+ 
+ 	return InputValidationResultOK, nil
+ }
+ 
+ func (os InputSelectionOptions) ValueToLabel(value string) (string, bool) {
+ 	for _, o := range os {
+ 		if o.Value == value {
+ 			return o.Label, true
+ 		}
+ 	}
+ 	return "", false
+ }
+ 
+ func (os InputSelectionOptions) LabelToValue(label string) (string, bool) {
+ 	for _, o := range os {
+ 		if o.Label == label {
+ 			return o.Value, true
+ 		}
+ 	}
+ 	return "", false
+ }
+ 
+ func (os InputSelectionOptions) OrderToValue(order uint16) (string, bool) {
+ 	for _, o := range os {
+ 		if o.Order == order {
+ 			return o.Value, true
+ 		}
+ 	}
+ 	return "", false
+ }
+ 
+ func (os InputLargeToggleOptions) ValueToLabel(value string) (string, bool) {
+ 	for _, o := range os {
+ 		if o.Value == value {
+ 			return o.Label, true
+ 		}
+ 	}
+ 	return "", false
+ }
+ 
+ func (os InputLargeToggleOptions) LabelToValue(label string) (string, bool) {
+ 	for _, o := range os {
+ 		if o.Label == label {
+ 			return o.Value, true
+ 		}
+ 	}
+ 	return "", false
+ }
+ 
+ func (os InputLargeToggleOptions) OrderToValue(order uint8) (string, bool) {
+ 	for _, o := range os {
+ 		if o.Order == order {
+ 			return o.Value, true
+ 		}
+ 	}
+ 	return "", false
+ }
+ 
```

## apps/persia/app/domain/procedureform/types_page.go
```diff
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 		sectionErrors, err := ValidateValuesBySection(
+ 			parsedValues,
+ 			section,
+ 			inputIDsMap,
+ 			fromAdmin,
+ 			isDraft,
+ 			isCSVUpload,
+ 		)
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 		if len(sectionErrors) > 0 {
+ func ValidateValuesBySection(
+ 	parsedValues domain.ParsedProcedureFormValues,
+ 	section Section,
+ 	inputIDsMap map[uuid.UUID]Input,
+ 	fromAdmin bool,
+ 	isDraft bool,
+ 	isCSVUpload bool,
+ ) (PageValidationErrors, error) {
+ 	groups := parsedValues[section.ID]
+ 	otherSectionValues := getOtherSectionValues(section.ID, parsedValues)
+ 	sectionErrors, err := section.ValidateValues(groups, otherSectionValues, fromAdmin, isDraft, isCSVUpload, inputIDsMap)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 	return sectionErrors, nil
+ }
+ 
+ 
+ func (ps PageByPageNumberForCSV) ConvertToCSVName(pageNum PageNumberForCSV) (string, error) {
+ 	page, ok := ps[pageNum]
+ 	if !ok {
+ 		return "", perrors.Internalf("failed to convert pageNum to csvName, pageNum: %d", pageNum)
+ 	}
+ 	return page.Name, nil
+ }
```

## apps/persia/app/domain/procedureform/version.go
```diff
+ 	CSVDefinitions                              CSVDefinitions
```

## apps/persia/app/handlers/http/oapi/api.gen.go
```diff
+ 	GetProcedurePagesByProcedureID(w http.ResponseWriter, r *http.Request, procedureId UUID)
+ 	GetProcedureCSVUploadLogsV2(w http.ResponseWriter, r *http.Request, procedureId UUID)
+ 	DownloadTemplateCSVForUploadByProcedureV2(w http.ResponseWriter, r *http.Request, procedureId UUID)
+ 	UpdateProcedureValueByCSVUploadV2(w http.ResponseWriter, r *http.Request, procedureId UUID)
+ func (_ Unimplemented) GetProcedurePagesByProcedureID(w http.ResponseWriter, r *http.Request, procedureId UUID) {
+ func (_ Unimplemented) GetProcedureCSVUploadLogsV2(w http.ResponseWriter, r *http.Request, procedureId UUID) {
+ func (_ Unimplemented) DownloadTemplateCSVForUploadByProcedureV2(w http.ResponseWriter, r *http.Request, procedureId UUID) {
+ func (_ Unimplemented) UpdateProcedureValueByCSVUploadV2(w http.ResponseWriter, r *http.Request, procedureId UUID) {
+ 	var procedureId UUID
+ 	var procedureId UUID
+ 	var procedureId UUID
+ 	var procedureId UUID
```

## apps/persia/app/handlers/http/oapi/spec.gen.go
```diff
+ 	"usrgThYIp/6CVAvSgS8xMIKV/nuP1anFQs+wOeDdbwQhij6oSvCkGKjGxpePQEWHh+Qh9M4Pyz84NKOH",
+ 	"/iGoRb+sni6+JC655ojHJyZNVutlvQVwSVA68QFaMjGpVU76gr+WK0+l6u3xiUn57U/yzhIsCz3a1QHq",
+ 	"srStA+SjmxfN0OFZ+gSJ2xXVUS0PMV9AuPDA6FcKzTuPIc8DItGhhlCUzHzjYbRoQYNSc1jhLYpeMKui",
+ 	"hCKI0Jt7K99jOE7QY+IqwhGSlzYQcBAanXx1pf72W+c7zMHO/f3Kr3tPFuqba75IzA527jvfWjHpFwaT",
+ 	"hgaUU+rovrTzN3+UkathRWMhnkmxAdujAYQKCLd3LjelV1d02hAzo4j7RWhrUzQ4XgzMJJXvxIaoxKZz",
+ 	"GR31SK2S7WusIH0averYJqGAMqKk6hvNBn/Ub8Gb92HRjOYpmmvXVVbs6o365lrjuzUz04wK8li9LV9b",
+ 	"1NDGCCRfTrM9D4rlfICm69MIgzY8DNirQcdzbbEjo3p/s/laSQbDa8YVcvpZAI81Xv1NQ8itWcFvN+Am",
+ 	"afy2ceNuc2VXK5VblR9vSeIzmBLw3Fw2Z66Zc32XHEdDQ8npwZTKEdrGl8lZZq5N21qzhlqxjCOk6fFq",
+ 	"8/UtKIAlc0ND1FB9+6l8eyEu//l6qPn78/rm143rFfndMrqTbVz/Y//pDVRf3Vy7frBTa959Jd+8e7Bz",
+ 	"vXnnN/mbG40Hmwc7tcajZ/Kfr+Wt56hgJlM6DxSVTl8oaA4D6cuXw9ogP0LlP5FwOB1NUEwiGqaiLBen",
+ 	"koBmKRbwo0ma52k2lQgN20uLohRDU3TkAqPW2HwaGjYjwXkpn2HicJRnL+bHNZkhdUaaeIZY8FOGTCsu",
+ 	"Q4GlUJ7W4aaaoWJaDZLoeDZbsssuEklEABOJU/woTVNRNslQKYYOU1yaiUdZjufTo2kX2dGG7IKUA91S",
+ 	"Dipc5WZNEnctmogEpEkHoZws+5FIKhFJ80yMpRJ0MklFeRCjEkyUppLxMMck0nwKcDxJIuHuSCTsRTN6",
+ 	"NUfGajEwHcGHGOBw2pdDa82w1eE1rzyRxCWH2VwxQQpj/FisIz9W377Rjh+LJ9N0KhwHFJ9Ipakox7IU",
+ 	"m0zwFBOJJ+kEH4txMdZlVeixSLt+LOZpmUjLYu47oGXpyKfRdIoDHEdTHB+PUFE2ylMJQEeoOB2JJ5kk",
+ 	"n06m3OXoQ3VdZdJKVeXaM2n+OXz9/QNhWLU75VQ4nqJjNKBGaYanoukoSyUAF6ZSbIqNgESY5uNMO04L",
+ 	"N2VrtWknpupnhqNJLsHGYlGKgdXRPAeo5ChDU+lwkuXCbDzFgF66LP9C+LwN0DbbYdFXCo0ROLJDM27v",
+ 	"P/pJElf3nqxAkB7t4Eo4Eg8Ybn3dV7m8jYxc1hXanTXDuhI6ZQQOLMyuKifn1B86Jq0gDGKgC63C4LrT",
+ 	"6hPl0xPOWqaOOrOJMElE8JpQqt5o/FGTxGWpIhLS8FcbtW1cMg8qV7Cpj5pVA78VWE5pl6bTN0ABHeh7",
+ 	"dzIG/SQK4pMEe7v2geTDkW0OoJvpkSzMIvPPsi+u66ljmMHPr0nVVzjQJ21y6+pXHIiMxmWQhryIHlHf",
+ 	"plXYxSsw4LWRL2ezJmSoe26wUChdDm/aIH26MBVIuKtlL6TAl6N+yD5rWPajCQ0CuNyQKmLj1ZJ8a9Ed",
+ 	"4cUIoMHZoKGY0FziFJ28QI+OMckxJvk3JhlPxplP3UCEEDqV16mGg5uqNL+NZgtfw+7Di8qbkrjqAgzU",
+ 	"4eT9TjZim2xnWm4G/mwHtcai3r4O6J2b+3u0GbXhhX0StrS8gEeS/4szTeOvRMjLPudx6WzKvVG9AA/5",
+ 	"gbLBkBr77zKAq6G2ZrliHHajgA5OxS3XX+/fO5kdDvqlVN2QqisomoFu8bTQh1ECot/TksB9u0oSRL6e",
+ 	"t7yEo7vIg51a47tXe8+X0H0yjnsV3bLbYwPdRhTQusFenDOYxF0Uq3MPPLjM2dUBlVuLE90hKU2r3MpO",
+ 	"Qf4DhvUOSZCfZITpj9IB8EN6mHag7z8Et2SAVre/CSuHo68fNx7+DyIKJSdvf5DJAoT74tx89UhzT7K4",
+ 	"9YEEsyeTJDAIzPUBzZsfKzkWrG9dPPO/n3RIA0K5AaHce0AoZ0TZD5VQ7nD89eHxyw3c9eG464GTHlDX",
+ 	"dZe6zh1VbVXeeIf8IXK8tjg+Qlhz8G8ploiP+A/Y8rrLludhe+wRW95h7pBtkOf1nDmvhd31i7kdW46+",
+ 	"1pZyTDj6Bke3940B0Lfr7ZAQUDelHhECHl02wO5J6gjV+/c6fjtgHwyqPNInGaHzJqJ/mAgHNIQDGsIB",
+ 	"DeGAhnBAQzigITxsGsIO98lBNqfnM4vyC/hTi0oqFxXR1+Kjv1uxkp7DlOFHdgXT6kQ0q7z5WR6FhJSD",
+ 	"C4adYsMAPVLb2Vwboj4r03QEDGFrTIYkcXVffNN8sU1EUMHWzigKex78F+BQ8czJOVV726gA84IcRAjp",
+ 	"NJZ/ksRVi8jEBZwjcwvmdHO93s9ADlGI+ACGblaHZuI+OE1Jb+GdcZpirMtBa6ohfx0RetNABDWITPQF",
+ 	"tNERZVc9MktCSB32GPFzZXMleBYMoaubfxkQu/Yl21wbChLkretRRoY7Sr6hE15Zs4q04JXtJqmsK5qx",
+ 	"5wEYVnBMOVMDNMH+plB9f7ZmD5Strns0jrW1T7fqI8/e2smqBmnVRRhZOWa5usSdDC91m8jfrEviMoRD",
+ 	"WYYo5N7AvaXq7c9CzpjYZyGYH3m98eC1HdjcnBq1X7nffPwMhjN2pPlVqXp7vyLWd58QQ2UoIoYxZzvn",
+ 	"smbAgSKIq6Hsy6Ece+k0yE8J06GxKE3Tw6FcJq99wDhTD+wg4agdb9DEfkoC/a5zwEbViu7Qb8DCVzQH",
+ 	"R3rq1IMunWfI4/FIkdi2aAbxmzYjLr4ZWDHYQwGQsNo1pzs8rJ2PfVCH2pG2qTtQW4qmAceQr6ywq6df",
+ 	"S+ls7l6vntSjW3AM895vmszJygYLvXGUuNvyssl0vLgDCdk9S7Iimnt874Dh2tDqIDb8VlzHNrGb6I4P",
+ 	"a3cPfmc/CkTIfedlVZY4ldbLlTHsAsjNZFkBjE9MflAoohK/vqIQc6awN++skMgf+4TUjVxBaQFXgUGD",
+ 	"k3M6R1+LFzIPVZNcaRYK1lE4qa9RO5jM2vhcI6CHE3/Rx9ZOxAWSzmKKFxHzj5O7DsHHkN4MlaYhNSFS",
+ 	"sXIxGxoLTQvCzNjISLbAsdnpQkkYi0RoemQGFEOKlqjtXNZ0UM18hZlk6kfIwZo/0TvVTNf8S+X1Cvtl",
+ 	"7Icny9kvdEIxZ6/Yh88XrAM8lYOX8sYH2AZPmMmcLL8ZL5eEQk771YfFQnmmxa9x87Z+rfU3YENO2aJP",
+ 	"rF+1NFLIzbD5OfNHZ3k+w1l6+kc+Y3noHDtXymZmHOKwSBUIirs5lZvJFuYAGGfzJzgOlCyS+iQjTE8X",
+ 	"stDWzWNmM1nchJXPzxTU4qJMIT8BBMH2qEOVMN85A/I5ViiVx6cL5RLIYL5x6hJi5rQoAZgF2cKMXX6n",
+ 	"pgqzJ8rCtP2zU+bKcfv3DS8R+vLzL/8vAAD//+hejnCWfQYA",
```

## apps/persia/app/handlers/http/procedure.go
```diff
+ 	procedureCSVV3Usecase           usecases.ProcedureCSVV3Usecase
+ 	procedureCSVV3Usecase usecases.ProcedureCSVV3Usecase,
+ 		procedureCSVV3Usecase:           procedureCSVV3Usecase,
```

## apps/persia/app/handlers/http/procedure_v2.go
```diff
+ 	"mime/multipart"
+ func (h ProcedureHandler) DownloadTemplateCSVForUploadByProcedureV2(w http.ResponseWriter, r *http.Request, procedureID procedureform.ProcedureID) {
+ 	err := middleware.HasRolePermissionForProcedure(ctx, domain.RoleTypeProcedurePermissionView, procedureID.String(), h.usecase)
+ 	if err := h.usecase.CheckIfAdminForProcedure(ctx, procedureID.String()); err != nil {
+ 	versionDetail, err := h.usecase.FindProcedureVersionDetailByProcedureID(ctx, procedureID)
+ 	if err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 		return
+ 	}
+ 
+ 	if versionDetail != nil && versionDetail.CSVDefinitions.HasDefinition() {
+ 		h.downloadTemplateCSVForUploadFromVersionDetail(w, r, procedureID, *versionDetail)
+ 		return
+ 	}
+ 
+ 		logCreationError := h.procedureCSVUsecase.CreateCSVDownloadSystemErrorLogV2(ctx, procedureID.String(), csvDownloadType)
+ 	zipName, fileEntries, alreadyCreatedLog, csvFileCreationError := h.procedureCSVUsecase.CreateTemplateCSVFilesV2(ctx, procedureID.String(), dir)
+ 		logCreationError := h.procedureCSVUsecase.CreateCSVDownloadSystemErrorLogV2(ctx, procedureID.String(), csvDownloadType)
+ 		err = h.procedureCSVUsecase.CreateCSVDownloadSuccessLogV2(ctx, procedureID.String(), csvDownloadType)
+ 			logCreationError := h.procedureCSVUsecase.CreateCSVDownloadSystemErrorLogV2(ctx, procedureID.String(), csvDownloadType)
+ func (h ProcedureHandler) downloadTemplateCSVForUploadFromVersionDetail(w http.ResponseWriter, r *http.Request, procedureID procedureform.ProcedureID, versionDetail procedureform.ProcedureVersionDetail) {
+ 	zipName, zipBytes, err := h.procedureCSVV3Usecase.GenerateDownloadCSVAndCreateDownloadLog(ctx, procedureID, versionDetail)
+ 	if err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 		return
+ 	}
+ 	httplib.RenderFile(ctx, w, r, zipName, httplib.ContentTypeApplicationZip.String(), zipBytes)
+ }
+ func (h ProcedureHandler) UpdateProcedureValueByCSVUploadV2(w http.ResponseWriter, r *http.Request, procedureID procedureform.ProcedureID) {
+ 	ctx := r.Context()
+ 
+ 	err := middleware.HasRolePermissionForProcedure(ctx, domain.RoleTypeProcedurePermissionAdmin, procedureID.String(), h.usecase)
+ 	if err := h.usecase.CheckIfAdminForProcedure(ctx, procedureID.String()); err != nil {
+ 	versionDetail, err := h.usecase.FindProcedureVersionDetailByProcedureID(ctx, procedureID)
+ 	if err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 		return
+ 	}
+ 
+ 	if versionDetail != nil && versionDetail.CSVDefinitions.HasDefinition() {
+ 		h.saveCSVProcedureValuesFromVersionDetail(w, r, procedureID, *versionDetail, procedureform.UploadCSVNumber(pageNum), file)
+ 		return
+ 	}
+ 
+ 	pageNumberForCSV := procedureform.PageNumberForCSV(pageNum)
+ 	csvErrors, err := h.procedureCSVUsecase.UploadProcedureValuesByCSVUploadV2(ctx, procedureID.String(), pageNumberForCSV, content)
+ 		if err := h.procedureCSVUsecase.CreateCSVUploadErrorLogV2(ctx, procedureID.String(), pageNumberForCSV, csvErrors); err != nil {
+ func (h ProcedureHandler) saveCSVProcedureValuesFromVersionDetail(
+ 	w http.ResponseWriter,
+ 	r *http.Request,
+ 	procedureID procedureform.ProcedureID,
+ 	versionDetail procedureform.ProcedureVersionDetail,
+ 	csvNumber procedureform.UploadCSVNumber,
+ 	csvFile multipart.File,
+ ) {
+ 	err := h.procedureCSVV3Usecase.SaveUploadedCSVValuesAndCreateUploadLog(ctx, procedureID, versionDetail, csvNumber, csvFile)
+ 	if err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 		return
+ 	}
+ 	httplib.RenderNoContent(w, r)
+ }
+ func (h ProcedureHandler) GetProcedureCSVUploadLogsV2(w http.ResponseWriter, r *http.Request, procedureID procedureform.ProcedureID) {
+ 	ctx := r.Context()
+ 
+ 	err := middleware.HasRolePermissionForProcedure(ctx, domain.RoleTypeProcedurePermissionView, procedureID.String(), h.usecase)
+ 	if err := h.usecase.CheckIfAdminForProcedure(ctx, procedureID.String()); err != nil {
+ func (h ProcedureHandler) GetProcedurePagesByProcedureID(w http.ResponseWriter, r *http.Request, procedureID procedureform.ProcedureID) {
+ 	if err := middleware.HasRolePermissionForProcedure(ctx, domain.RoleTypeProcedurePermissionView, procedureID.String(), h.usecase); err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 	if err := h.usecase.CheckIfAdminForProcedure(ctx, procedureID.String()); err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 	versionDetail, err := h.usecase.FindProcedureVersionDetailByProcedureID(ctx, procedureID)
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 		return
+ 	}
+ 
+ 	if versionDetail != nil && versionDetail.CSVDefinitions.HasDefinition() {
+ 		h.getProcedureDownloadCSVNamesFromVersionDetail(w, r, *versionDetail)
+ 		return
+ 	}
+ 
+ 	pages, err := h.usecase.GetProcedurePageNamesByProcedureID(ctx, procedureID.String())
+ 	if err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ func (h ProcedureHandler) getProcedureDownloadCSVNamesFromVersionDetail(w http.ResponseWriter, r *http.Request, versionDetail procedureform.ProcedureVersionDetail) {
+ 	ctx := r.Context()
+ 
+ 	defByNumber, err := h.procedureCSVV3Usecase.GetCSVDefinitionByCSVNumber(ctx, versionDetail)
+ 	if err != nil {
+ 		httplib.RenderError(ctx, w, r, perrors.AsIs(err))
+ 		return
+ 	}
+ 
+ 	httplib.RenderJSON(w, r, defByNumber.ToResponse())
+ }
+ 
```

## apps/persia/app/lib/testutils/error.go
```diff
+ 
+ func AssertErrorAs[T error](expected T) assert.ErrorAssertionFunc {
+ 	return func(t assert.TestingT, err error, i ...interface{}) bool {
+ 		var target T
+ 		if assert.ErrorAs(t, err, &target) {
+ 			return assert.Equal(t, expected, target)
+ 		}
+ 		return false
+ 	}
+ }
```

## apps/persia/app/registry/repositories.go
```diff
+ 	repositories.NewProcedureCSVLogRepository,
+ 	repositories.NewProcedureCSVLogRepository,
```

## apps/persia/app/registry/usecases.go
```diff
+ 	usecases.NewProcedureCSVV3Usecase,
```

## apps/persia/app/registry/wire_gen.go
```diff
+ 	procedureCSVUsecase := usecases.NewProcedureCSVUsecase(procedureTemplateRegistry, procedureRepository, memberRepository, memberUnitValueRepository, memberProcedureFormInitialValueRepository, procedureBulkConfirmHistoryRepository, transaction)
+ 	procedureCSVLogRepository := repositories.NewProcedureCSVLogRepository(db2)
+ 	procedureCSVV3Usecase := usecases.NewProcedureCSVV3Usecase(procedureTemplateRegistry, procedureRepository, procedureFormValueRepository, memberRepository, memberUnitValueRepository, memberProcedureFormInitialValueRepository, procedureBulkConfirmHistoryRepository, procedureCSVLogRepository, transaction)
+ 	procedureHandler := http.NewProcedureHandler(procedureUsecase, bulkCreateDocumentUsecase, procedureCSVUsecase, procedureCSVV3Usecase, procedureTemplateSettingUsecase, memberUsecase)
+ 	procedureCSVUsecase := usecases.NewProcedureCSVUsecase(procedureTemplateRegistry, procedureRepository, memberRepository, memberUnitValueRepository, memberProcedureFormInitialValueRepository, procedureBulkConfirmHistoryRepository, transaction)
+ 	procedureCSVLogRepository := repositories.NewProcedureCSVLogRepository(db2)
+ 	procedureCSVV3Usecase := usecases.NewProcedureCSVV3Usecase(procedureTemplateRegistry, procedureRepository, procedureFormValueRepository, memberRepository, memberUnitValueRepository, memberProcedureFormInitialValueRepository, procedureBulkConfirmHistoryRepository, procedureCSVLogRepository, transaction)
+ 	procedureHandler := http.NewProcedureHandler(procedureUsecase, bulkCreateDocumentUsecase, procedureCSVUsecase, procedureCSVV3Usecase, procedureTemplateSettingUsecase, memberUsecase)
```

## apps/persia/app/repositories/db/queries/member_procedure_form_initial_values.sql.go
```diff
+ // Code generated by sqlc. DO NOT EDIT.
+ // versions:
+ //   sqlc v1.29.0
+ // source: member_procedure_form_initial_values.sql
+ 
+ package queries
+ 
+ import (
+ 	"context"
+ 	"fmt"
+ 
+ 	uuid "github.com/gofrs/uuid/v5"
+ 	"github.com/lib/pq"
+ )
+ 
+ const deleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs = `-- name: DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs :exec
+ DELETE FROM member_procedure_form_initial_values
+ WHERE company_id = $1
+     AND procedure_id = $2
+     AND member_id = ANY($3::uuid[])
+     AND unit_id = ANY($4::uuid[])
+ `
+ 
+ type DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDsParams struct {
+ 	CompanyID   int64       `db:"company_id"`
+ 	ProcedureID uuid.UUID   `db:"procedure_id"`
+ 	MemberIds   []uuid.UUID `db:"member_ids"`
+ 	UnitIds     []uuid.UUID `db:"unit_ids"`
+ }
+ 
+ func (q *Queries) DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs(ctx context.Context, arg DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDsParams) error {
+ 	_, err := q.db.ExecContext(ctx, deleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs,
+ 		arg.CompanyID,
+ 		arg.ProcedureID,
+ 		pq.Array(arg.MemberIds),
+ 		pq.Array(arg.UnitIds),
+ 	)
+ 	if err != nil {
+ 		err = fmt.Errorf("query DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs: %w", err)
+ 	}
+ 	return err
+ }
+ 
+ const getMemberProcedureFormInitialValuesForTest = `-- name: GetMemberProcedureFormInitialValuesForTest :many
+ SELECT id, company_id, procedure_id, member_id, unit_id, group_id, group_index, value_index, initial_value, page_id, created_at FROM member_procedure_form_initial_values
+ `
+ 
+ func (q *Queries) GetMemberProcedureFormInitialValuesForTest(ctx context.Context) ([]MemberProcedureFormInitialValue, error) {
+ 	rows, err := q.db.QueryContext(ctx, getMemberProcedureFormInitialValuesForTest)
+ 	if err != nil {
+ 		return nil, fmt.Errorf("query GetMemberProcedureFormInitialValuesForTest: %w", err)
+ 	}
+ 	defer rows.Close()
+ 	items := []MemberProcedureFormInitialValue{}
+ 	for rows.Next() {
+ 		var i MemberProcedureFormInitialValue
+ 		if err := rows.Scan(
+ 			&i.ID,
+ 			&i.CompanyID,
+ 			&i.ProcedureID,
+ 			&i.MemberID,
+ 			&i.UnitID,
+ 			&i.GroupID,
+ 			&i.GroupIndex,
+ 			&i.ValueIndex,
+ 			&i.InitialValue,
+ 			&i.PageID,
+ 			&i.CreatedAt,
+ 		); err != nil {
+ 			return nil, fmt.Errorf("query GetMemberProcedureFormInitialValuesForTest: %w", err)
+ 		}
+ 		items = append(items, i)
+ 	}
+ 	if err := rows.Close(); err != nil {
+ 		return nil, fmt.Errorf("query GetMemberProcedureFormInitialValuesForTest: %w", err)
+ 	}
+ 	if err := rows.Err(); err != nil {
+ 		return nil, fmt.Errorf("query GetMemberProcedureFormInitialValuesForTest: %w", err)
+ 	}
+ 	return items, nil
+ }
```

## apps/persia/app/repositories/db/queries/procedure_csv_download_logs.sql.go
```diff
+ // Code generated by sqlc. DO NOT EDIT.
+ // versions:
+ //   sqlc v1.29.0
+ // source: procedure_csv_download_logs.sql
+ 
+ package queries
+ 
+ import (
+ 	"context"
+ 	"fmt"
+ 	"time"
+ 
+ 	uuid "github.com/gofrs/uuid/v5"
+ 	"github.com/sqlc-dev/pqtype"
+ )
+ 
+ const getProcedureCsvDownloadLogsForTest = `-- name: GetProcedureCsvDownloadLogsForTest :many
+ SELECT id, company_id, member_id, procedure_id, error, error_details, created_at, type FROM procedure_csv_download_logs
+ `
+ 
+ func (q *Queries) GetProcedureCsvDownloadLogsForTest(ctx context.Context) ([]ProcedureCsvDownloadLog, error) {
+ 	rows, err := q.db.QueryContext(ctx, getProcedureCsvDownloadLogsForTest)
+ 	if err != nil {
+ 		return nil, fmt.Errorf("query GetProcedureCsvDownloadLogsForTest: %w", err)
+ 	}
+ 	defer rows.Close()
+ 	items := []ProcedureCsvDownloadLog{}
+ 	for rows.Next() {
+ 		var i ProcedureCsvDownloadLog
+ 		if err := rows.Scan(
+ 			&i.ID,
+ 			&i.CompanyID,
+ 			&i.MemberID,
+ 			&i.ProcedureID,
+ 			&i.Error,
+ 			&i.ErrorDetails,
+ 			&i.CreatedAt,
+ 			&i.Type,
+ 		); err != nil {
+ 			return nil, fmt.Errorf("query GetProcedureCsvDownloadLogsForTest: %w", err)
+ 		}
+ 		items = append(items, i)
+ 	}
+ 	if err := rows.Close(); err != nil {
+ 		return nil, fmt.Errorf("query GetProcedureCsvDownloadLogsForTest: %w", err)
+ 	}
+ 	if err := rows.Err(); err != nil {
+ 		return nil, fmt.Errorf("query GetProcedureCsvDownloadLogsForTest: %w", err)
+ 	}
+ 	return items, nil
+ }
+ 
+ const insertProcedureCSVDownloadLogs = `-- name: InsertProcedureCSVDownloadLogs :exec
+ INSERT INTO procedure_csv_download_logs
+ (company_id, member_id, procedure_id, error, error_details, "type", created_at)
+ VALUES
+ ($1, $2, $3, $4, $5, $6, $7::TIMESTAMP WITH TIME ZONE)
+ `
+ 
+ type InsertProcedureCSVDownloadLogsParams struct {
+ 	CompanyID    int64                 `db:"company_id"`
+ 	MemberID     string                `db:"member_id"`
+ 	ProcedureID  uuid.UUID             `db:"procedure_id"`
+ 	Error        int16                 `db:"error"`
+ 	ErrorDetails pqtype.NullRawMessage `db:"error_details"`
+ 	Type         int16                 `db:"type"`
+ 	CreatedAt    time.Time             `db:"created_at"`
+ }
+ 
+ func (q *Queries) InsertProcedureCSVDownloadLogs(ctx context.Context, arg InsertProcedureCSVDownloadLogsParams) error {
+ 	_, err := q.db.ExecContext(ctx, insertProcedureCSVDownloadLogs,
+ 		arg.CompanyID,
+ 		arg.MemberID,
+ 		arg.ProcedureID,
+ 		arg.Error,
+ 		arg.ErrorDetails,
+ 		arg.Type,
+ 		arg.CreatedAt,
+ 	)
+ 	if err != nil {
+ 		err = fmt.Errorf("query InsertProcedureCSVDownloadLogs: %w", err)
+ 	}
+ 	return err
+ }
```

## apps/persia/app/repositories/db/queries/procedure_csv_upload_logs.sql.go
```diff
+ // Code generated by sqlc. DO NOT EDIT.
+ // versions:
+ //   sqlc v1.29.0
+ // source: procedure_csv_upload_logs.sql
+ 
+ package queries
+ 
+ import (
+ 	"context"
+ 	"fmt"
+ 	"time"
+ 
+ 	uuid "github.com/gofrs/uuid/v5"
+ 	"github.com/sqlc-dev/pqtype"
+ )
+ 
+ const getProcedureCsvUploadLogsForTest = `-- name: GetProcedureCsvUploadLogsForTest :many
+ SELECT id, company_id, admin_id, procedure_id, page_number, error, error_details, created_at FROM procedure_csv_upload_logs
+ `
+ 
+ func (q *Queries) GetProcedureCsvUploadLogsForTest(ctx context.Context) ([]ProcedureCsvUploadLog, error) {
+ 	rows, err := q.db.QueryContext(ctx, getProcedureCsvUploadLogsForTest)
+ 	if err != nil {
+ 		return nil, fmt.Errorf("query GetProcedureCsvUploadLogsForTest: %w", err)
+ 	}
+ 	defer rows.Close()
+ 	items := []ProcedureCsvUploadLog{}
+ 	for rows.Next() {
+ 		var i ProcedureCsvUploadLog
+ 		if err := rows.Scan(
+ 			&i.ID,
+ 			&i.CompanyID,
+ 			&i.AdminID,
+ 			&i.ProcedureID,
+ 			&i.PageNumber,
+ 			&i.Error,
+ 			&i.ErrorDetails,
+ 			&i.CreatedAt,
+ 		); err != nil {
+ 			return nil, fmt.Errorf("query GetProcedureCsvUploadLogsForTest: %w", err)
+ 		}
+ 		items = append(items, i)
+ 	}
+ 	if err := rows.Close(); err != nil {
+ 		return nil, fmt.Errorf("query GetProcedureCsvUploadLogsForTest: %w", err)
+ 	}
+ 	if err := rows.Err(); err != nil {
+ 		return nil, fmt.Errorf("query GetProcedureCsvUploadLogsForTest: %w", err)
+ 	}
+ 	return items, nil
+ }
+ 
+ const insertProcedureCSVUploadLogs = `-- name: InsertProcedureCSVUploadLogs :exec
+ INSERT INTO procedure_csv_upload_logs
+ (company_id, admin_id, procedure_id, page_number, error, error_details, created_at)
+ VALUES
+ ($1, $2, $3, $4, $5, $6, $7::TIMESTAMP WITH TIME ZONE)
+ `
+ 
+ type InsertProcedureCSVUploadLogsParams struct {
+ 	CompanyID    int64                 `db:"company_id"`
+ 	AdminID      uuid.UUID             `db:"admin_id"`
+ 	ProcedureID  uuid.UUID             `db:"procedure_id"`
+ 	PageNumber   int16                 `db:"page_number"`
+ 	Error        int16                 `db:"error"`
+ 	ErrorDetails pqtype.NullRawMessage `db:"error_details"`
+ 	CreatedAt    time.Time             `db:"created_at"`
+ }
+ 
+ func (q *Queries) InsertProcedureCSVUploadLogs(ctx context.Context, arg InsertProcedureCSVUploadLogsParams) error {
+ 	_, err := q.db.ExecContext(ctx, insertProcedureCSVUploadLogs,
+ 		arg.CompanyID,
+ 		arg.AdminID,
+ 		arg.ProcedureID,
+ 		arg.PageNumber,
+ 		arg.Error,
+ 		arg.ErrorDetails,
+ 		arg.CreatedAt,
+ 	)
+ 	if err != nil {
+ 		err = fmt.Errorf("query InsertProcedureCSVUploadLogs: %w", err)
+ 	}
+ 	return err
+ }
```

## apps/persia/app/repositories/db/sql/member_procedure_form_initial_values.sql
```diff
+ -- name: DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs :exec
+ DELETE FROM member_procedure_form_initial_values
+ WHERE company_id = $1
+     AND procedure_id = $2
+     AND member_id = ANY(@member_ids::uuid[])
+     AND unit_id = ANY(@unit_ids::uuid[]);
+ 
+ -- name: GetMemberProcedureFormInitialValuesForTest :many
+ SELECT * FROM member_procedure_form_initial_values;
+ 
```

## apps/persia/app/repositories/db/sql/procedure_csv_download_logs.sql
```diff
+ -- name: InsertProcedureCSVDownloadLogs :exec
+ INSERT INTO procedure_csv_download_logs
+ (company_id, member_id, procedure_id, error, error_details, "type", created_at)
+ VALUES
+ (@company_id, @member_id, @procedure_id, @error, @error_details, @type, @created_at::TIMESTAMP WITH TIME ZONE);
+ 
+ -- name: GetProcedureCsvDownloadLogsForTest :many
+ SELECT * FROM procedure_csv_download_logs;
```

## apps/persia/app/repositories/db/sql/procedure_csv_upload_logs.sql
```diff
+ -- name: InsertProcedureCSVUploadLogs :exec
+ INSERT INTO procedure_csv_upload_logs
+ (company_id, admin_id, procedure_id, page_number, error, error_details, created_at)
+ VALUES
+ (@company_id, @admin_id, @procedure_id, @page_number, @error, @error_details, @created_at::TIMESTAMP WITH TIME ZONE);
+ 
+ -- name: GetProcedureCsvUploadLogsForTest :many
+ SELECT * FROM procedure_csv_upload_logs;
```

## apps/persia/app/repositories/member_procedure_form_initial_value.go
```diff
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db/queries"
+ 	BulkDeleteInitialValuesByInputIDs(ctx context.Context, procedureID procedureform.ProcedureID, memberIDs domain.MemberIDs, inputIDs []procedureform.InputID) error
+ 
+ func (r memberProcedureFormInitialValueRepository) BulkDeleteInitialValuesByInputIDs(
+ 	ctx context.Context,
+ 	procedureID procedureform.InputID,
+ 	memberIDs domain.MemberIDs,
+ 	inputIDs []procedureform.InputID,
+ ) error {
+ 	memberUUIDs, err := util.NewUUIDsFromString(memberIDs...)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 	q := r.db.Queries(ctx)
+ 	companyID := ctxlib.GetCompanyIDFromContext(ctx)
+ 	err = q.DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDs(ctx, queries.DeleteMemberProcedureFormInitialValuesByProcedureIDAndMemberIDsAndInputIDsParams{
+ 		CompanyID:   int64(companyID),
+ 		ProcedureID: procedureID,
+ 		MemberIds:   memberUUIDs,
+ 		UnitIds:     inputIDs,
+ 	})
+ 	if err != nil {
+ 		return perrors.Internal(err)
+ 	}
+ 	return nil
+ }
```

## apps/persia/app/repositories/member_procedure_form_initial_value_test.go
```diff
+ package repositories_test
+ 	"time"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db/queries"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/testhelper"
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 			testDB().RunWithContext(ctx, t, func(ctx context.Context, db db.DB) {
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(db)
+ 
+ func Test_memberProcedureFormInitialValueRepository_BulkDeleteInitialValuesByInputIDs(t *testing.T) {
+ 	now := time.Date(2025, time.June, 1, 0, 0, 0, 0, time.UTC)
+ 
+ 	sharedInserter := testhelper.NewInserter().
+ 		Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 		Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query)
+ 
+ 	tests := []struct {
+ 		name         string
+ 		companyID    uint64
+ 		procedureID  procedureform.ProcedureID
+ 		memberIDs    []string
+ 		inputIDs     []procedureform.InputID
+ 		inserter     testhelper.Inserter
+ 		expected     []queries.MemberProcedureFormInitialValue
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name:        "success: 3 initial records, delete 1 record (partial match)",
+ 			companyID:   1,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{testhelper.MemberTestData1.ID.String()},
+ 			inputIDs: []procedureform.InputID{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I2_1.InputID,
+ 			},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I2_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I3_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I3_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 1 initial record, delete 0 record (filtered by inputIDs)",
+ 			companyID:   1,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{testhelper.MemberTestData1.ID.String()},
+ 			inputIDs:    []procedureform.InputID{uuid.Nil},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 1 initial record, delete 0 record (filtered by memberIDs)",
+ 			companyID:   1,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{uuid.Nil.String()},
+ 			inputIDs: []procedureform.InputID{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.InputID,
+ 			},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 1 initial record, delete 0 record (filtered by companyID)",
+ 			companyID:   999,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{testhelper.MemberTestData1.ID.String()},
+ 			inputIDs: []procedureform.InputID{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.InputID,
+ 			},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 1 initial record, delete 0 record (filtered by procedureID)",
+ 			companyID:   1,
+ 			procedureID: uuid.Nil,
+ 			memberIDs:   []string{testhelper.MemberTestData1.ID.String()},
+ 			inputIDs: []procedureform.InputID{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.InputID,
+ 			},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 0 initial records, delete 0 record",
+ 			companyID:   1,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{testhelper.MemberTestData1.ID.String()},
+ 			inputIDs: []procedureform.InputID{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.InputID,
+ 			},
+ 			inserter:     sharedInserter,
+ 			expected:     []queries.MemberProcedureFormInitialValue{},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 1 initial record, delete 0 record (empty inputIDs)",
+ 			companyID:   1,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{testhelper.MemberTestData1.ID.String()},
+ 			inputIDs:    []procedureform.InputID{},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:        "success: 1 initial record, delete 0 record (empty memberIDs)",
+ 			companyID:   1,
+ 			procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 			memberIDs:   []string{},
+ 			inputIDs: []procedureform.InputID{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.InputID,
+ 			},
+ 			inserter: sharedInserter.
+ 				Add(queries.MemberProcedureFormInitialValuesTable.TableName,
+ 					testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 				),
+ 			expected: []queries.MemberProcedureFormInitialValue{
+ 				testhelper.MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1.ToQuery(1, testhelper.MemberTestData1.ID.String(), now),
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			freshDB().Run(t, func(ctx context.Context, dbConn db.DB) {
+ 				ctx = ctxlib.SetContextWithCompanyID(ctx, tt.companyID)
+ 				repo := repositories.NewMemberProcedureFormInitialValueRepository(dbConn)
+ 				queries := dbConn.Queries(ctx)
+ 
+ 				conn, err := dbConn.Conn(ctx)
+ 				require.NoError(t, err)
+ 				require.NoError(t, tt.inserter.InsertAll(ctx, conn))
+ 
+ 				err = repo.BulkDeleteInitialValuesByInputIDs(ctx, tt.procedureID, tt.memberIDs, tt.inputIDs)
+ 				tt.errAssertion(t, err)
+ 
+ 				if err != nil {
+ 					return
+ 				}
+ 
+ 				got, err := queries.GetMemberProcedureFormInitialValuesForTest(ctx)
+ 				require.NoError(t, err)
+ 				for i := range got {
+ 					got[i].ID = 0 // IDは自動採番されるため、テストで確認しない
+ 				}
+ 
+ 				assert.ElementsMatch(t, tt.expected, got)
+ 			})
+ 		})
+ 	}
+ }
```

## apps/persia/app/repositories/procedure.go
```diff
+ 	GetMemberProcedureStatusMap(ctx context.Context, procedureID string, memberIDs []string) (map[domain.MemberID]domain.MemberProcedureStatus, error)
+ 	BulkSaveFormValues(ctx context.Context, procedureID string, parsedValuesByMemberID map[domain.MemberID]domain.ParsedProcedureFormValues) error
+ 	BulkDeleteFormValues(ctx context.Context, procedureID string, memberIDs []string, unitIDsToDelete []procedureform.InputID) error
+ func (r procedureRepository) GetMemberProcedureStatusMap(ctx context.Context, procedureID string, memberIDs []string) (map[domain.MemberID]domain.MemberProcedureStatus, error) {
+ 		return map[domain.MemberID]domain.MemberProcedureStatus{}, sterrors.Errorf(": %w", err)
+ 		return map[domain.MemberID]domain.MemberProcedureStatus{}, sterrors.Errorf(": %w", err)
+ 	statusMap := make(map[domain.MemberID]domain.MemberProcedureStatus, len(memberProcedures))
+ 		statusMap[domain.MemberID(memberProcedure.MemberID)] = domain.MemberProcedureStatus(memberProcedure.MemberProcedureStatus)
+ 	parsedValuesByMemberID map[domain.MemberID]domain.ParsedProcedureFormValues,
+ 							MemberID:    memberID.String(),
+ func (r procedureRepository) BulkDeleteFormValues(ctx context.Context, procedureID string, memberIDs []string, unitIDsToDelete []procedureform.InputID) error {
+ 		models.MemberProcedureFormValueWhere.UnitID.IN(util.ToStringSlice(unitIDsToDelete)),
+ 	uploadResultType domain.CSVUploadResultType,
+ 		Error:       int16(uploadResultType),
+ 		Status:     domain.CSVUploadResultType(model.Error),
```

## apps/persia/app/repositories/procedure_csv_logs.go
```diff
+ package repositories
+ 
+ import (
+ 	"context"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/ctxfunc"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/ctxlib"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db/queries"
+ 	"github.com/sqlc-dev/pqtype"
+ )
+ 
+ type ProcedureCSVLogRepository interface {
+ 	CreateCSVDownloadLog(ctx context.Context, procedureID procedureform.ProcedureID, downloadType domain.ProcedureCSVDownloadType, result procedureform.CSVDownloadResult) error
+ 	CreateCSVUploadLog(ctx context.Context, procedureID procedureform.ProcedureID, csvNumber procedureform.UploadCSVNumber, result procedureform.CSVUploadResult) error
+ }
+ 
+ type procedureCSVLogRepository struct {
+ 	db db.DB
+ }
+ 
+ func NewProcedureCSVLogRepository(db db.DB) ProcedureCSVLogRepository {
+ 	return procedureCSVLogRepository{
+ 		db: db,
+ 	}
+ }
+ 
+ func (r procedureCSVLogRepository) CreateCSVDownloadLog(ctx context.Context, procedureID procedureform.ProcedureID, downloadType domain.ProcedureCSVDownloadType, result procedureform.CSVDownloadResult) error {
+ 	q := r.db.Queries(ctx)
+ 	companyID := ctxlib.GetCompanyIDFromContext(ctx)
+ 	memberID := ctxlib.GetOperatorIDFromContext(ctx)
+ 
+ 	params := queries.InsertProcedureCSVDownloadLogsParams{
+ 		CompanyID:   int64(companyID),
+ 		ProcedureID: procedureID,
+ 		MemberID:    memberID,
+ 		Error:       result.ResultType(),
+ 		Type:        int16(downloadType),
+ 		CreatedAt:   ctxfunc.GetNow(ctx),
+ 	}
+ 	if result.HasErrorDetails() {
+ 		detail, err := result.MarshalJSON()
+ 		if err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 		params.ErrorDetails = pqtype.NullRawMessage{
+ 			Valid:      true,
+ 			RawMessage: detail,
+ 		}
+ 	}
+ 	err := q.InsertProcedureCSVDownloadLogs(ctx, params)
+ 	if err != nil {
+ 		return perrors.Internal(err)
+ 	}
+ 
+ 	return nil
+ }
+ 
+ func (r procedureCSVLogRepository) CreateCSVUploadLog(ctx context.Context, procedureID procedureform.ProcedureID, csvNumber procedureform.UploadCSVNumber, result procedureform.CSVUploadResult) error {
+ 	q := r.db.Queries(ctx)
+ 	companyID := ctxlib.GetCompanyIDFromContext(ctx)
+ 	adminID := ctxlib.GetOperatorUUIDFromContext(ctx)
+ 	params := queries.InsertProcedureCSVUploadLogsParams{
+ 		CompanyID:   int64(companyID),
+ 		AdminID:     adminID,
+ 		ProcedureID: procedureID,
+ 		PageNumber:  int16(csvNumber),
+ 		Error:       int16(result.ResultType()),
+ 		CreatedAt:   ctxfunc.GetNow(ctx),
+ 	}
+ 
+ 	if result.HasErrorDetails() {
+ 		detail, err := result.MarshalJSON()
+ 		if err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 		params.ErrorDetails = pqtype.NullRawMessage{
+ 			Valid:      true,
+ 			RawMessage: detail,
+ 		}
+ 	}
+ 	err := q.InsertProcedureCSVUploadLogs(ctx, params)
+ 	if err != nil {
+ 		return perrors.Internal(err)
+ 	}
+ 
+ 	return nil
+ }
```

## apps/persia/app/repositories/procedure_csv_logs_test.go
```diff
+ package repositories_test
+ 
+ import (
+ 	"context"
+ 	"testing"
+ 	"time"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/ctxfunc"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/ctxlib"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/testutils"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db/queries"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/testhelper"
+ 	"github.com/sqlc-dev/pqtype"
+ 	"github.com/stretchr/testify/assert"
+ 	"github.com/stretchr/testify/require"
+ )
+ 
+ func Test_procedureCSVLogsRepository_CreateCSVDownloadLog(t *testing.T) {
+ 	now := time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)
+ 
+ 	type args struct {
+ 		procedureID  procedureform.ProcedureID
+ 		downloadType domain.ProcedureCSVDownloadType
+ 		result       procedureform.CSVDownloadResult
+ 	}
+ 	tests := []struct {
+ 		name         string
+ 		companyID    uint64
+ 		operatorID   string
+ 		inserter     testhelper.Inserter
+ 		args         args
+ 		want         []queries.ProcedureCsvDownloadLog
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name:       "success: create CSV download success log",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 				downloadType: domain.ProcedureCSVDownloadTypeProcedureV1,
+ 				result:       procedureform.NewCSVDownloadSuccess(),
+ 			},
+ 			want: []queries.ProcedureCsvDownloadLog{
+ 				{
+ 					CompanyID:   int64(testhelper.CompanyTestData1.CompanyID),
+ 					ProcedureID: testhelper.ProcedureTestData1.Query.ID,
+ 					MemberID:    testhelper.MemberTestData1.ID.String(),
+ 					Error:       domain.CSVDownloadSuccess,
+ 					Type:        int16(domain.ProcedureCSVDownloadTypeProcedureV1),
+ 					CreatedAt:   now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV download system error log",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 				downloadType: domain.ProcedureCSVDownloadTypeTemplate,
+ 				result:       procedureform.CSVDownloadSystemError{},
+ 			},
+ 			want: []queries.ProcedureCsvDownloadLog{
+ 				{
+ 					CompanyID:   int64(testhelper.CompanyTestData1.CompanyID),
+ 					ProcedureID: testhelper.ProcedureTestData1.Query.ID,
+ 					MemberID:    testhelper.MemberTestData1.ID.String(),
+ 					Error:       domain.CSVDownloadSystemError,
+ 					Type:        int16(domain.ProcedureCSVDownloadTypeTemplate),
+ 					CreatedAt:   now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV download data error log",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 				downloadType: domain.ProcedureCSVDownloadTypeTemplate,
+ 				result: procedureform.CSVDownloadDataError{
+ 					Details: []domain.CSVDownloadErrorToSaveV2{
+ 						{
+ 							MemberID: testhelper.MemberTestData1.ID.String(),
+ 							ErrorLocations: []domain.ProcedureCSVCreationErrorLocation{
+ 								{
+ 									FileName:   "test.csv",
+ 									InputLabel: "section1 > row1 > input1",
+ 								},
+ 							},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			want: []queries.ProcedureCsvDownloadLog{
+ 				{
+ 					CompanyID:   int64(testhelper.CompanyTestData1.CompanyID),
+ 					ProcedureID: testhelper.ProcedureTestData1.Query.ID,
+ 					MemberID:    testhelper.MemberTestData1.ID.String(),
+ 					Error:       domain.CSVDownloadDataError,
+ 					Type:        int16(domain.ProcedureCSVDownloadTypeTemplate),
+ 					ErrorDetails: pqtype.NullRawMessage{
+ 						Valid: true,
+ 						RawMessage: testutils.MustMarshalJson(
+ 							[]domain.CSVDownloadErrorToSaveV2{
+ 								{
+ 									MemberID: testhelper.MemberTestData1.ID.String(),
+ 									ErrorLocations: []domain.ProcedureCSVCreationErrorLocation{
+ 										{
+ 											FileName:   "test.csv",
+ 											InputLabel: "section1 > row1 > input1",
+ 										},
+ 									},
+ 								},
+ 							},
+ 						),
+ 					},
+ 					CreatedAt: now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV download data error log (empty details)",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 				downloadType: domain.ProcedureCSVDownloadTypeTemplate,
+ 				result: procedureform.CSVDownloadDataError{
+ 					Details: []domain.CSVDownloadErrorToSaveV2{},
+ 				},
+ 			},
+ 			want: []queries.ProcedureCsvDownloadLog{
+ 				{
+ 					CompanyID:    int64(testhelper.CompanyTestData1.CompanyID),
+ 					ProcedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 					MemberID:     testhelper.MemberTestData1.ID.String(),
+ 					Error:        domain.CSVDownloadDataError,
+ 					Type:         int16(domain.ProcedureCSVDownloadTypeTemplate),
+ 					ErrorDetails: pqtype.NullRawMessage{},
+ 					CreatedAt:    now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			freshDB().Run(t, func(ctx context.Context, db db.DB) {
+ 				ctx = ctxlib.SetContextWithCompanyID(ctx, tt.companyID)
+ 				ctx = ctxlib.SetContextWithOperatorID(ctx, tt.operatorID)
+ 				ctx = ctxfunc.WithFixedTime(ctx, now)
+ 
+ 				conn, err := db.Conn(ctx)
+ 				require.NoError(t, err)
+ 				require.NoError(t, tt.inserter.InsertAll(ctx, conn))
+ 
+ 				repo := repositories.NewProcedureCSVLogRepository(db)
+ 
+ 				err = repo.CreateCSVDownloadLog(ctx, tt.args.procedureID, tt.args.downloadType, tt.args.result)
+ 				tt.errAssertion(t, err)
+ 				if err != nil {
+ 					return
+ 				}
+ 
+ 				got, err := db.Queries(ctx).GetProcedureCsvDownloadLogsForTest(ctx)
+ 				for i := range got {
+ 					got[i].ID = 0 // IDは自動採番なので比較対象から除外
+ 				}
+ 				require.NoError(t, err)
+ 				assert.Equal(t, tt.want, got)
+ 			})
+ 		})
+ 	}
+ }
+ 
+ func Test_procedureCSVLogsRepository_CreateCSVUploadLog(t *testing.T) {
+ 	now := time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)
+ 
+ 	type args struct {
+ 		procedureID procedureform.ProcedureID
+ 		csvNumber   procedureform.UploadCSVNumber
+ 		result      procedureform.CSVUploadResult
+ 	}
+ 	tests := []struct {
+ 		name         string
+ 		companyID    uint64
+ 		operatorID   string
+ 		args         args
+ 		want         []queries.ProcedureCsvUploadLog
+ 		inserter     testhelper.Inserter
+ 		errAssertion assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name:       "success: create CSV upload success log",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 				csvNumber:   procedureform.UploadCSVNumber(1),
+ 				result:      procedureform.NewCSVUploadResultSuccess(),
+ 			},
+ 			want: []queries.ProcedureCsvUploadLog{
+ 				{
+ 					CompanyID:   int64(testhelper.CompanyTestData1.CompanyID),
+ 					AdminID:     testhelper.MemberTestData1.ID,
+ 					ProcedureID: testhelper.ProcedureTestData1.Query.ID,
+ 					PageNumber:  int16(1),
+ 					Error:       int16(domain.CSVUploadSuccess),
+ 					CreatedAt:   now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV upload reading error log",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 				csvNumber:   procedureform.UploadCSVNumber(2),
+ 				result: procedureform.CSVUploadReadingError{
+ 					Details: domain.CSVUploadReadingErrorsToSaveV2{
+ 						{
+ 							RowNumber: testutils.ToPtr(2),
+ 							ErrorType: domain.ProcedureCSVErrorTypeNotIncludedEmployeeNumberOrMailaddress,
+ 						},
+ 						{
+ 							RowNumber: testutils.ToPtr(1),
+ 							ErrorType: domain.ProcedureCSVErrorTypeDuplicateHeader,
+ 						},
+ 						{
+ 							RowNumber: nil,
+ 							ErrorType: domain.ProcedureCSVErrorTypeWrongPage,
+ 						},
+ 					},
+ 				},
+ 			},
+ 			want: []queries.ProcedureCsvUploadLog{
+ 				{
+ 					CompanyID:   int64(testhelper.CompanyTestData1.CompanyID),
+ 					AdminID:     testhelper.MemberTestData1.ID,
+ 					ProcedureID: testhelper.ProcedureTestData1.Query.ID,
+ 					PageNumber:  int16(2),
+ 					Error:       int16(domain.CSVUploadReadingError),
+ 					ErrorDetails: pqtype.NullRawMessage{
+ 						Valid: true,
+ 						RawMessage: testutils.MustMarshalJson(
+ 							domain.CSVUploadReadingErrorsToSaveV2{
+ 								// 順序はRowNumberの昇順にソートされる
+ 								{
+ 									RowNumber: nil,
+ 									ErrorType: domain.ProcedureCSVErrorTypeWrongPage,
+ 								},
+ 								{
+ 									RowNumber: testutils.ToPtr(1),
+ 									ErrorType: domain.ProcedureCSVErrorTypeDuplicateHeader,
+ 								},
+ 								{
+ 									RowNumber: testutils.ToPtr(2),
+ 									ErrorType: domain.ProcedureCSVErrorTypeNotIncludedEmployeeNumberOrMailaddress,
+ 								},
+ 							}),
+ 					},
+ 					CreatedAt: now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV upload reading error log (empty details)",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 				csvNumber:   procedureform.UploadCSVNumber(2),
+ 				result: procedureform.CSVUploadReadingError{
+ 					Details: domain.CSVUploadReadingErrorsToSaveV2{},
+ 				},
+ 			},
+ 			want: []queries.ProcedureCsvUploadLog{
+ 				{
+ 					CompanyID:    int64(testhelper.CompanyTestData1.CompanyID),
+ 					AdminID:      testhelper.MemberTestData1.ID,
+ 					ProcedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 					PageNumber:   int16(2),
+ 					Error:        int16(domain.CSVUploadReadingError),
+ 					ErrorDetails: pqtype.NullRawMessage{},
+ 					CreatedAt:    now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV upload data error log",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 				csvNumber:   procedureform.UploadCSVNumber(2),
+ 				result: procedureform.CSVUploadDataError{
+ 					Details: domain.CSVUploadDataErrorsToSaveV2{
+ 						{
+ 							HierarchyLabel: "Section3 > Row3 > Input3",
+ 							RowNumber:      3,
+ 							ErrorType:      domain.ProcedureCSVErrorTypeCannotConvertToDate,
+ 							Option:         domain.ProcedureCSVUploadDataErrorOption{},
+ 						},
+ 						{
+ 							HierarchyLabel: "Section1 > Row1 > Input1",
+ 							RowNumber:      1,
+ 							ErrorType:      domain.ProcedureCSVErrorTypeLargerThanMax,
+ 							Option: domain.ProcedureCSVUploadDataErrorOption{
+ 								Max: testutils.ToPtr(100),
+ 							},
+ 						},
+ 						{
+ 							HierarchyLabel: "Section2 > Row2 > Input2",
+ 							RowNumber:      2,
+ 							ErrorType:      domain.ProcedureCSVErrorTypeSmallerThanMin,
+ 							Option: domain.ProcedureCSVUploadDataErrorOption{
+ 								Min: testutils.ToPtr(10),
+ 							},
+ 						},
+ 					},
+ 				},
+ 			},
+ 			want: []queries.ProcedureCsvUploadLog{
+ 				{
+ 					CompanyID:   int64(testhelper.CompanyTestData1.CompanyID),
+ 					AdminID:     testhelper.MemberTestData1.ID,
+ 					ProcedureID: testhelper.ProcedureTestData1.Query.ID,
+ 					PageNumber:  int16(2),
+ 					Error:       int16(domain.CSVUploadDataError),
+ 					ErrorDetails: pqtype.NullRawMessage{
+ 						Valid: true,
+ 						RawMessage: testutils.MustMarshalJson(
+ 							domain.CSVUploadDataErrorsToSaveV2{
+ 								// 順序はRowNumberの昇順にソートされる
+ 								{
+ 									HierarchyLabel: "Section1 > Row1 > Input1",
+ 									RowNumber:      1,
+ 									ErrorType:      domain.ProcedureCSVErrorTypeLargerThanMax,
+ 									Option: domain.ProcedureCSVUploadDataErrorOption{
+ 										Max: testutils.ToPtr(100),
+ 									},
+ 								},
+ 								{
+ 									HierarchyLabel: "Section2 > Row2 > Input2",
+ 									RowNumber:      2,
+ 									ErrorType:      domain.ProcedureCSVErrorTypeSmallerThanMin,
+ 									Option: domain.ProcedureCSVUploadDataErrorOption{
+ 										Min: testutils.ToPtr(10),
+ 									},
+ 								},
+ 								{
+ 									HierarchyLabel: "Section3 > Row3 > Input3",
+ 									RowNumber:      3,
+ 									ErrorType:      domain.ProcedureCSVErrorTypeCannotConvertToDate,
+ 									Option:         domain.ProcedureCSVUploadDataErrorOption{},
+ 								},
+ 							}),
+ 					},
+ 					CreatedAt: now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:       "success: create CSV upload data error log (empty details)",
+ 			companyID:  testhelper.CompanyTestData1.CompanyID,
+ 			operatorID: testhelper.MemberTestData1.ID.String(),
+ 			inserter: testhelper.NewInserter().
+ 				Add(queries.CompaniesTable.TableName, testhelper.CompanyContactTestData1.Query).
+ 				Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query),
+ 			args: args{
+ 				procedureID: testhelper.ProcedureTestData1.Query.ID,
+ 				csvNumber:   procedureform.UploadCSVNumber(2),
+ 				result: procedureform.CSVUploadDataError{
+ 					Details: domain.CSVUploadDataErrorsToSaveV2{},
+ 				},
+ 			},
+ 			want: []queries.ProcedureCsvUploadLog{
+ 				{
+ 					CompanyID:    int64(testhelper.CompanyTestData1.CompanyID),
+ 					AdminID:      testhelper.MemberTestData1.ID,
+ 					ProcedureID:  testhelper.ProcedureTestData1.Query.ID,
+ 					PageNumber:   int16(2),
+ 					Error:        int16(domain.CSVUploadDataError),
+ 					ErrorDetails: pqtype.NullRawMessage{},
+ 					CreatedAt:    now,
+ 				},
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 	}
+ 
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			freshDB().Run(t, func(ctx context.Context, db db.DB) {
+ 				ctx = ctxlib.SetContextWithCompanyID(ctx, tt.companyID)
+ 				ctx = ctxlib.SetContextWithOperatorID(ctx, tt.operatorID)
+ 				ctx = ctxfunc.WithFixedTime(ctx, now)
+ 
+ 				conn, err := db.Conn(ctx)
+ 				require.NoError(t, err)
+ 				require.NoError(t, tt.inserter.InsertAll(ctx, conn))
+ 
+ 				repo := repositories.NewProcedureCSVLogRepository(db)
+ 
+ 				err = repo.CreateCSVUploadLog(ctx, tt.args.procedureID, tt.args.csvNumber, tt.args.result)
+ 				tt.errAssertion(t, err)
+ 				if err != nil {
+ 					return
+ 				}
+ 
+ 				got, err := db.Queries(ctx).GetProcedureCsvUploadLogsForTest(ctx)
+ 				for i := range got {
+ 					got[i].ID = 0 // IDは自動採番なので比較対象から除外
+ 				}
+ 				require.NoError(t, err)
+ 				assert.Equal(t, tt.want, got)
+ 			})
+ 		})
+ 	}
+ }
```

## apps/persia/app/repositories/procedure_test.go
```diff
+ 		parsedValuesByMemberID map[domain.MemberID]domain.ParsedProcedureFormValues
+ 			parsedValuesByMemberID: map[domain.MemberID]domain.ParsedProcedureFormValues{
+ 			parsedValuesByMemberID: map[domain.MemberID]domain.ParsedProcedureFormValues{},
+ 											MemberID:    memberID.String(),
+ 		unitIDsToDelete []procedureform.InputID
+ 			unitIDsToDelete: util.NewFixedUUIDs(
+ 			),
+ 			unitIDsToDelete: util.NewFixedUUIDs(
+ 			),
+ 			unitIDsToDelete: []procedureform.InputID{uuid.Nil},
+ 			diff:            0,
+ 			unitIDsToDelete: util.NewFixedUUIDs(
+ 			),
+ 			unitIDsToDelete: []procedureform.InputID{},
+ 			unitIDsToDelete: []procedureform.InputID{},
```

## apps/persia/app/repositories/testhelper/test_data_member_procedure_form_initial_values.go
```diff
+ package testhelper
+ 
+ import (
+ 	"time"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/util"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db/queries"
+ )
+ 
+ var MemberProcedureFormInitialValueTestData_PageID1 = util.NewFixedUUID("b36b2df5-3925-4c3a-be02-4eba9fb7d8c4")
+ 
+ // 命名規則: MemberProcedureFormInitialValueTestData_<ProcedureTestDataID>_<PageID>_<GroupID/DG>_<InputID>_<ValueIndex + 1> (DG = Default Group)
+ var (
+ 	MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I1_1 = MemberProcedureFormInitialValueTestData{
+ 		ProcedureID:  ProcedureTestData1.Query.ID,
+ 		GroupID:      procedureform.DefaultGroupID,
+ 		GroupIndex:   0,
+ 		InputID:      util.NewFixedUUID("32c97935-e645-4675-ba92-63a2d4200cbb"),
+ 		ValueIndex:   0,
+ 		InitialValue: "test-value-p1-pg1-dg-i1-1",
+ 		PageID:       MemberProcedureFormInitialValueTestData_PageID1,
+ 	}
+ 
+ 	MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I2_1 = MemberProcedureFormInitialValueTestData{
+ 		ProcedureID:  ProcedureTestData1.Query.ID,
+ 		GroupID:      procedureform.DefaultGroupID,
+ 		GroupIndex:   0,
+ 		InputID:      util.NewFixedUUID("38e063a7-5e80-42cf-9bc1-57a2b4519225"),
+ 		ValueIndex:   0,
+ 		InitialValue: "test-value-p1-pg1-dg-i2-1",
+ 		PageID:       MemberProcedureFormInitialValueTestData_PageID1,
+ 	}
+ 
+ 	MemberProcedureFormInitialValueTestData_P1_Pg1_DG_I3_1 = MemberProcedureFormInitialValueTestData{
+ 		ProcedureID:  ProcedureTestData1.Query.ID,
+ 		GroupID:      procedureform.DefaultGroupID,
+ 		GroupIndex:   0,
+ 		InputID:      util.NewFixedUUID("0121cad1-cbe2-48bc-8024-4c0cd03bc802"),
+ 		ValueIndex:   0,
+ 		InitialValue: "test-value-p1-pg1-dg-i3-1",
+ 		PageID:       MemberProcedureFormInitialValueTestData_PageID1,
+ 	}
+ )
+ 
+ type MemberProcedureFormInitialValueTestData struct {
+ 	ProcedureID  procedureform.ProcedureID
+ 	GroupID      procedureform.GroupID
+ 	GroupIndex   int16
+ 	InputID      procedureform.InputID
+ 	ValueIndex   int16
+ 	InitialValue string
+ 	PageID       procedureform.PageID
+ }
+ 
+ func (d MemberProcedureFormInitialValueTestData) ToQuery(companyID uint64, memberID string, createdAt time.Time) queries.MemberProcedureFormInitialValue {
+ 	return queries.MemberProcedureFormInitialValue{
+ 		CompanyID:    int64(companyID),
+ 		ProcedureID:  d.ProcedureID,
+ 		MemberID:     memberID,
+ 		UnitID:       d.InputID,
+ 		GroupID:      d.GroupID,
+ 		GroupIndex:   d.GroupIndex,
+ 		ValueIndex:   d.ValueIndex,
+ 		InitialValue: d.InitialValue,
+ 		PageID:       d.PageID,
+ 		CreatedAt:    createdAt,
+ 	}
+ }
```

## apps/persia/app/usecases/egov_apply.go
```diff
+ 	status, exists := memberProcedureStatusMap[memberID]
+ 			notConfirmedMemberIDs = append(notConfirmedMemberIDs, memberID.String())
```

## apps/persia/app/usecases/egov_apply_test.go
```diff
+ 					Return(map[domain.MemberID]domain.MemberProcedureStatus{
+ 						domain.MemberID(memberUUID1.String()): domain.MemberProcedureStatusInputConfirmed,
+ 						domain.MemberID(memberUUID2.String()): domain.MemberProcedureStatusInputConfirmed,
+ 					Return(map[domain.MemberID]domain.MemberProcedureStatus{
+ 						domain.MemberID(memberUUID1.String()): domain.MemberProcedureStatusInputConfirmed,
+ 						domain.MemberID(memberUUID2.String()): domain.MemberProcedureStatusInputConfirmed,
+ 					Return(map[domain.MemberID]domain.MemberProcedureStatus{
+ 						domain.MemberID(memberUUID1.String()): domain.MemberProcedureStatusInputConfirmed,
+ 					Return(map[domain.MemberID]domain.MemberProcedureStatus{}, perrors.Internalf("GetMemberProcedureStatusMap error"))
```

## apps/persia/app/usecases/procedure.go
```diff
+ 	FindProcedureVersionDetailByProcedureID(ctx context.Context, procedureID procedureform.ProcedureID) (*procedureform.ProcedureVersionDetail, error)
+ 		if found && memberProcedureByMemberID[domain.MemberID(member.ID)] == domain.MemberProcedureStatusInputConfirmed {
```

## apps/persia/app/usecases/procedure_csv.go
```diff
+ 	GetCSVUploadLogsV2(ctx context.Context, procedureID procedureform.ProcedureID) (domain.ProcedureCSVUploadLogsResponseV2, error)
+ 	templateRegistry                    procedureform.ProcedureTemplateRegistry
+ 	templateRegistry procedureform.ProcedureTemplateRegistry,
+ 		templateRegistry:                    templateRegistry,
```

## apps/persia/app/usecases/procedure_csv_v2.go
```diff
+ 	map[domain.MemberID]domain.MemberProcedureStatus,
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
+ 				skipMemberIDSet[memberID] = struct{}{}
+ func gatherExtraUpdatedInputs(p procedureform.Page, appearedSectionID map[uuid.UUID]struct{}) []procedureform.InputID {
+ 	extraUpdatedInputs := []procedureform.InputID{}
+ 					extraUpdatedInputs = append(extraUpdatedInputs, i.ID)
+ ) []procedureform.InputID {
+ 	inputIDs := make([]procedureform.InputID, 0)
+ 		inputIDs = append(inputIDs, s.InputID)
+ 	parsedValuesByMemberID map[domain.MemberID]domain.ParsedProcedureFormValues,
+ 			dataErrorList = append(dataErrorList, procedurecsvv2.ToCSVDataErrors(validationErrors, idToLabelMap, idToValidationDetailMap, csvRowIndexMap, rowIdxToRowNumberMap, memberID.String())...)
+ 		status := memberStatusMap[domain.MemberID(memberRowDetail.MemberID)]
+ 	[]procedureform.InputID,
+ ) (map[domain.MemberID]domain.ParsedProcedureFormValues, map[procedurecsvv2.TemplateCSVRowIdentifier]int, map[uuid.UUID]struct{}, domain.CSVUploadReadingErrorsToSaveV2, domain.CSVUploadDataErrorsToSaveV2) {
+ 	parsedValuesByMemberID := make(map[domain.MemberID]domain.ParsedProcedureFormValues, membersCnt)
+ 		parsedValuesByMemberID[domain.MemberID(memberRowDetail.MemberID)] = parsedValues
+ func (u procedureCSVUsecase) GetCSVUploadLogsV2(ctx context.Context, procedureID procedureform.ProcedureID) (domain.ProcedureCSVUploadLogsResponseV2, error) {
+ 	logs, err := u.procedureRepo.GetCSVUploadLogsV2(ctx, procedureID.String())
+ 		return domain.ProcedureCSVUploadLogsResponseV2{}, perrors.AsIs(err)
+ 	converter, err := u.GetCSVNumToCSVNameConverter(ctx, procedureID)
+ 		return domain.ProcedureCSVUploadLogsResponseV2{}, perrors.AsIs(err)
+ 		return domain.ProcedureCSVUploadLogsResponseV2{}, perrors.AsIs(err)
+ 		name, err := converter.ConvertToCSVName(procedureform.PageNumberForCSV(log.PageNumber))
+ 		if err != nil {
+ 			return domain.ProcedureCSVUploadLogsResponseV2{}, perrors.AsIs(err)
+ 		}
+ 			PageName:   name,
+ func (u procedureCSVUsecase) GetCSVNumToCSVNameConverter(ctx context.Context, procedureID procedureform.ProcedureID) (procedureform.CSVNumToCSVNameConverter, error) {
+ 	_, versionID, err := u.procedureRepo.GetProcedureTemplateIDAndVersionIDByProcedureID(ctx, procedureID)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	versionDetail, exists := u.templateRegistry.GetByVersionID(versionID)
+ 	if exists && versionDetail.CSVDefinitions.HasDefinition() {
+ 		return versionDetail.CSVDefinitions.GetCSVDefinitionByCSVNumber(), nil
+ 	}
+ 
+ 	procedureVersion, err := u.procedureRepo.FindProcedureVersionByProcedureID(ctx, procedureID.String())
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	pages, err := procedureformv2.GetFormPagesForCSV(procedureVersion.FormIDServer)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	return pages, nil
+ }
+ 
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
+ 	memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus,
+ 		memberProcedureStatus := memberProcedureStatusMap[domain.MemberID(member.ID)]
```

## apps/persia/app/usecases/procedure_csv_v2_test.go
```diff
+ 	memberProcedureStatusMap := map[domain.MemberID]domain.MemberProcedureStatus{
+ 		memberID1: domain.MemberProcedureStatusInputConfirmed,
+ 		memberID2: domain.MemberProcedureStatusMemberInProgress,
+ 		memberID3: domain.MemberProcedureStatusNone,
+ 		memberProcedureStatusMap map[domain.MemberID]domain.MemberProcedureStatus
```

## apps/persia/app/usecases/procedure_csv_v3.go
```diff
+ package usecases
+ 
+ import (
+ 	"context"
+ 	"io"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db"
+ )
+ 
+ type ProcedureCSVV3Usecase interface {
+ 	GetCSVDefinitionByCSVNumber(ctx context.Context, versionDetail procedureform.ProcedureVersionDetail) (procedureform.CSVDefinitionByCSVNumber, error)
+ 
+ 	SaveUploadedCSVValuesAndCreateUploadLog(ctx context.Context, procedureID procedureform.ProcedureID, versionDetail procedureform.ProcedureVersionDetail, csvNumber procedureform.UploadCSVNumber, csvFile io.Reader) error
+ 	GenerateDownloadCSVAndCreateDownloadLog(ctx context.Context, procedureID procedureform.ProcedureID, versionDetail procedureform.ProcedureVersionDetail) (string, []byte, error)
+ }
+ 
+ type procedureCSVV3Usecase struct {
+ 	templateRegistry                    procedureform.ProcedureTemplateRegistry
+ 	procedureRepo                       repositories.ProcedureRepository
+ 	procedureFormValueRepo              repositories.ProcedureFormValueRepository
+ 	memberRepo                          repositories.MemberRepository
+ 	memberUnitValueRepo                 repositories.MemberUnitValueRepository
+ 	memberProcedureFormInitialValueRepo repositories.MemberProcedureFormInitialValueRepository
+ 	procedureBulkConfirmHistoryRepo     repositories.ProcedureBulkConfirmHistoryRepository
+ 	procedureCSVLogRepo                 repositories.ProcedureCSVLogRepository
+ 
+ 	tx db.Transaction
+ }
+ 
+ func NewProcedureCSVV3Usecase(
+ 	templateRegistry procedureform.ProcedureTemplateRegistry,
+ 	procedureRepo repositories.ProcedureRepository,
+ 	procedureFormValueRepo repositories.ProcedureFormValueRepository,
+ 	memberRepo repositories.MemberRepository,
+ 	memberUnitValueRepo repositories.MemberUnitValueRepository,
+ 	memberProcedureFormInitialValueRepo repositories.MemberProcedureFormInitialValueRepository,
+ 	procedureBulkConfirmHistoryRepo repositories.ProcedureBulkConfirmHistoryRepository,
+ 	procedureCSVLogRepo repositories.ProcedureCSVLogRepository,
+ 	tx db.Transaction,
+ ) ProcedureCSVV3Usecase {
+ 	return procedureCSVV3Usecase{
+ 		templateRegistry:                    templateRegistry,
+ 		procedureRepo:                       procedureRepo,
+ 		procedureFormValueRepo:              procedureFormValueRepo,
+ 		memberRepo:                          memberRepo,
+ 		memberUnitValueRepo:                 memberUnitValueRepo,
+ 		memberProcedureFormInitialValueRepo: memberProcedureFormInitialValueRepo,
+ 		procedureBulkConfirmHistoryRepo:     procedureBulkConfirmHistoryRepo,
+ 		procedureCSVLogRepo:                 procedureCSVLogRepo,
+ 		tx:                                  tx,
+ 	}
+ }
+ 
+ func (u procedureCSVV3Usecase) GetCSVDefinitionByCSVNumber(ctx context.Context, versionDetail procedureform.ProcedureVersionDetail) (procedureform.CSVDefinitionByCSVNumber, error) {
+ 	csvDefs := versionDetail.CSVDefinitions
+ 	if len(csvDefs.Definitions) == 0 {
+ 		return procedureform.CSVDefinitionByCSVNumber{}, perrors.Internalf("csv definitions is not set: versionID: %v", versionDetail.Version)
+ 	}
+ 	return csvDefs.GetCSVDefinitionByCSVNumber(), nil
+ }
```

## apps/persia/app/usecases/procedure_csv_v3_download.go
```diff
+ package usecases
+ 
+ import (
+ 	"archive/zip"
+ 	"bytes"
+ 	"context"
+ 	csvPkg "encoding/csv"
+ 	"errors"
+ 	"maps"
+ 	"slices"
+ 	"time"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/util"
+ )
+ 
+ func (u procedureCSVV3Usecase) GenerateDownloadCSVAndCreateDownloadLog(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	versionDetail procedureform.ProcedureVersionDetail,
+ ) (string, []byte, error) {
+ 	procedureStatus, err := u.procedureRepo.GetProcedureStatusByID(ctx, procedureID.String())
+ 	if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	if procedureStatus != domain.ProcedureStatusInProgress {
+ 		return "", nil, perrors.Forbiddenf("procedure status is not in progress")
+ 	}
+ 
+ 	zipName, zipData, downloadErr := u.generateDownloadCSV(ctx, procedureID, versionDetail)
+ 	if downloadErr != nil {
+ 		isDataErr, createLogErr := u.createDownloadErrorLog(ctx, procedureID, downloadErr)
+ 		if createLogErr != nil {
+ 			// ログの記録の際にもエラーが発生した場合は、元のエラーに結合して返す
+ 			combinedErr := errors.Join(downloadErr, createLogErr)
+ 			return "", nil, perrors.Internal(combinedErr)
+ 		}
+ 
+ 		if isDataErr {
+ 			return zipName, zipData, perrors.BadRequest(downloadErr)
+ 		}
+ 
+ 		return "", nil, perrors.AsIs(downloadErr)
+ 	}
+ 
+ 	return zipName, zipData, nil
+ }
+ 
+ // createDownloadErrorLog は、CSVダウンロード時に発生したエラーのログを記録する.
+ // 第1返り値は、エラーが dataError かどうかを示すbool値
+ // 第2返り値は、ログの記録に失敗した場合のエラーを返す.
+ func (u procedureCSVV3Usecase) createDownloadErrorLog(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	downloadErr error,
+ ) (bool, error) {
+ 	downloadType := domain.ProcedureCSVDownloadTypeTemplate
+ 	if dataError := procedureform.AsCSVDownloadDataError(downloadErr); dataError != nil {
+ 		if err := u.procedureCSVLogRepo.CreateCSVDownloadLog(ctx, procedureID, downloadType, dataError); err != nil {
+ 			return true, perrors.AsIs(err)
+ 		}
+ 		return true, nil
+ 	}
+ 
+ 	// dataError 以外の場合は systemError としてログを作成する
+ 	if err := u.procedureCSVLogRepo.CreateCSVDownloadLog(ctx, procedureID, downloadType, procedureform.NewCSVDownloadSystemError()); err != nil {
+ 		return false, perrors.AsIs(err)
+ 	}
+ 
+ 	return false, nil
+ }
+ 
+ func (u procedureCSVV3Usecase) generateDownloadCSV(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	versionDetail procedureform.ProcedureVersionDetail,
+ ) (string, []byte, error) {
+ 	csvDefs := versionDetail.CSVDefinitions
+ 
+ 	procedure, err := u.procedureRepo.GetProcedureWithAllMemberIDsByID(ctx, procedureID.String())
+ 	if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	members, err := u.getSortedMembers(ctx, procedure.MemberIDs)
+ 	if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	memberIDs := members.ToMemberIDs()
+ 
+ 	memberProcedureStatusMap, err := u.procedureRepo.GetMemberProcedureStatusMap(ctx, procedureID.String(), memberIDs)
+ 	if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	memberSourceByMember, err := procedureform.NewCSVMemberHeaderSourceMap(members, memberProcedureStatusMap)
+ 	if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	formValuesByMember, err := u.getFormValuesByMember(ctx, procedureID, memberIDs, csvDefs)
+ 	if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	zipData, err := u.createZip(csvDefs, members, memberSourceByMember, formValuesByMember)
+ 	if dataError := procedureform.AsCSVDownloadDataError(err); dataError != nil {
+ 		// データエラーの場合でもCSVのダウンロードはさせるので、ここの第一返り値、第二返り値は空値にしていない.
+ 		return csvDefs.ZipName, zipData, perrors.AsIs(dataError)
+ 	} else if err != nil {
+ 		return "", nil, perrors.AsIs(err)
+ 	}
+ 
+ 	return csvDefs.ZipName, zipData, nil
+ }
+ 
+ // Bengal と同じ並び順の従業員一覧(domain.Members)を取得する.
+ func (u procedureCSVV3Usecase) getSortedMembers(ctx context.Context, memberIDs domain.MemberIDs) (domain.Members, error) {
+ 	members, err := u.memberRepo.GetMembersByIDs(ctx, memberIDs)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	// ソートのみに使用するため権限を無視する。
+ 	// 権限を見てしまうと閲覧権限がない時に並び順が変わってしまうため。
+ 	membersForSort, err := u.memberRepo.GetMembersFromAdminByIDs(ctx, memberIDs)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	membersForSortMap := membersForSort.KeyByMemberID()
+ 	slices.SortStableFunc(members, func(a, b domain.Member) int {
+ 		aMember, aExists := membersForSortMap[domain.MemberID(a.ID)]
+ 		bMember, bExists := membersForSortMap[domain.MemberID(b.ID)]
+ 		if !aExists || !bExists {
+ 			// 通常到達しない
+ 			return 0
+ 		}
+ 		return aMember.CompareByBengalOrder(bMember)
+ 	})
+ 
+ 	return members, nil
+ }
+ 
+ func (u procedureCSVV3Usecase) createZip(
+ 	csvDefs procedureform.CSVDefinitions,
+ 	members domain.Members,
+ 	memberSourceByMember map[domain.MemberID]procedureform.CSVMemberHeaderSource,
+ 	formValuesByMember map[domain.MemberID]procedureform.FormValues,
+ ) ([]byte, error) {
+ 	var buf bytes.Buffer
+ 	zipWriter := zip.NewWriter(&buf)
+ 
+ 	entireDataError := procedureform.NewCSVDownloadDataError(domain.CSVDownloadErrorsToSaveV2{})
+ 	// 各CSV定義に基づいてCSVファイルを生成する
+ 	for _, def := range csvDefs.Definitions {
+ 		// CSVを生成
+ 		csv, err := u.createCSV(def, members, memberSourceByMember, formValuesByMember)
+ 		if dataError := procedureform.AsCSVDownloadDataError(err); dataError != nil {
+ 			entireDataError = entireDataError.Append(dataError.Details)
+ 		} else if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		// Zipに格納
+ 		fileWriter, err := zipWriter.CreateHeader(&zip.FileHeader{
+ 			Name:     def.GetPathInZip(),
+ 			Method:   zip.Deflate,
+ 			Modified: time.Now(),
+ 		})
+ 		if err != nil {
+ 			return nil, perrors.Internal(err)
+ 		}
+ 		csvWriter := csvPkg.NewWriter(fileWriter)
+ 		err = csvWriter.WriteAll(csv.ToMatrix())
+ 		if err != nil {
+ 			return nil, perrors.Internal(err)
+ 		}
+ 	}
+ 
+ 	if err := zipWriter.Close(); err != nil {
+ 		return nil, perrors.Internal(err)
+ 	}
+ 
+ 	if entireDataError.HasErrorDetails() {
+ 		// データエラーの場合でもCSVのダウンロードはさせるので、ここの第一返り値は空値にしていない.
+ 		return buf.Bytes(), perrors.AsIs(entireDataError)
+ 	}
+ 
+ 	return buf.Bytes(), nil
+ }
+ 
+ func (u procedureCSVV3Usecase) createCSV(
+ 	def procedureform.CSVDefinition,
+ 	members domain.Members,
+ 	memberSourceByMemberID map[domain.MemberID]procedureform.CSVMemberHeaderSource,
+ 	formValuesByMember map[domain.MemberID]procedureform.FormValues,
+ ) (domainCsv.CSV, error) {
+ 	dataErrorByFile := procedureform.NewCSVDownloadDataError(domain.CSVDownloadErrorsToSaveV2{})
+ 
+ 	// 空のCSVを生成
+ 	csvBuilder := domainCsv.NewCSVBuilder()
+ 
+ 	// ヘッダー情報を書き込む
+ 	def.HeaderDefinitions.WriteHeaderToCSV(csvBuilder)
+ 
+ 	// CSVの一番左上にファイル名を書き込む
+ 	csvBuilder.Write(0, 0, def.Name)
+ 
+ 	// 従業員ごとに rows を生成し、CSVに書き込む
+ 	for _, member := range members {
+ 		memberID := domain.MemberID(member.ID)
+ 
+ 		formValues := formValuesByMember[memberID]
+ 		memberSource := memberSourceByMemberID[memberID]
+ 		err := u.generateCSVRowsByMember(memberID, def, memberSource, formValues, csvBuilder)
+ 		if dataError := procedureform.AsCSVDownloadDataError(err); dataError != nil {
+ 			dataErrorByFile = dataErrorByFile.Append(dataError.Details)
+ 		} else if err != nil {
+ 			return domainCsv.CSV{}, perrors.AsIs(err)
+ 		}
+ 	}
+ 
+ 	if dataErrorByFile.HasErrorDetails() {
+ 		// データエラーの場合でもCSVのダウンロードはさせるので、ここの第一返り値は空値にしていない.
+ 		return csvBuilder.Build(), perrors.AsIs(dataErrorByFile)
+ 	}
+ 
+ 	return csvBuilder.Build(), nil
+ }
+ 
+ // 従業員ごとにCSVの行を生成する
+ func (u procedureCSVV3Usecase) generateCSVRowsByMember(
+ 	memberID domain.MemberID,
+ 	def procedureform.CSVDefinition,
+ 	memberSource procedureform.CSVMemberHeaderSource,
+ 	formValues procedureform.FormValues,
+ 	csvBuilder domainCsv.CSVBuilder,
+ ) error {
+ 	groupIdx := 0
+ 	dataErrorBuilder := procedureform.NewCSVDownloadDataErrorBuilder(memberID, def.Name)
+ 
+ 	for {
+ 		// rowBuilderを初期化
+ 		rowBuilder := csvBuilder.NewRow()
+ 
+ 		// 従業員情報が書かれた列を書き込む
+ 		writeMemberHeaders(rowBuilder, def.HeaderDefinitions.MemberHeaders, memberSource, dataErrorBuilder)
+ 
+ 		// 各フォームの値が書かれた列を書き込む
+ 		isLastRow := writeInputHeaders(rowBuilder, def.HeaderDefinitions.InputHeaders, formValues, groupIdx, dataErrorBuilder)
+ 
+ 		// 組み立てた Row を Append する
+ 		csvBuilder = rowBuilder.Append()
+ 
+ 		// 最後の行であれば次の loop には入らずここでbreakする
+ 		if isLastRow {
+ 			break
+ 		}
+ 
+ 		groupIdx++
+ 	}
+ 
+ 	dataError := dataErrorBuilder.Build()
+ 	if dataError.HasErrorDetails() {
+ 		return perrors.AsIs(dataError)
+ 	}
+ 
+ 	return nil
+ }
+ 
+ func writeMemberHeaders(
+ 	rowBuilder domainCsv.RowBuilder,
+ 	memberHeaders procedureform.CSVMemberHeaders,
+ 	memberSource procedureform.CSVMemberHeaderSource,
+ 	dataErrorBuilder *procedureform.CSVDownloadDataErrorBuilder,
+ ) {
+ 	for _, memberHeader := range memberHeaders {
+ 		value, err := memberHeader.Calculate(memberSource)
+ 		if err != nil {
+ 			dataErrorBuilder.AddErrorLocation(memberHeader.Label.ToHierarchyLabel())
+ 		}
+ 		rowBuilder.AddCells(value)
+ 	}
+ }
+ 
+ func writeInputHeaders(
+ 	rowBuilder domainCsv.RowBuilder,
+ 	inputHeaders procedureform.CSVInputHeaders,
+ 	formValues procedureform.FormValues,
+ 	groupIdx int,
+ 	dataErrorBuilder *procedureform.CSVDownloadDataErrorBuilder,
+ ) bool {
+ 	// isLastRowは組み立てている Row がその従業員の最後の行かどうかを示すフラグ
+ 	isLastRow := true
+ 
+ 	for _, inputHeader := range inputHeaders {
+ 		groups := formValues.GetGroupedInputValuesList(inputHeader.Input.ID)
+ 
+ 		// アップロード・ダウンロードCSVの、一人の従業員に対する行数は、CSVに含まれる Input の グループ数の最大に等しい
+ 		// もし、すべてのグループに対して groupIdx+1(=今追加しようとしているグループが何個目か) >= len(groups) が成り立っているならば
+ 		// その従業員の行はこれが最後の行である. そうでなければ、まだ追加すべき行があることになる
+ 		if groupIdx+1 < len(groups) {
+ 			isLastRow = false
+ 		}
+ 
+ 		inputValues := formValues.GetGroupedInputValuesByIndex(inputHeader.Input.ID, groupIdx).GetInputValues()
+ 		value, err := inputHeader.Converter.ToCSVValue(inputValues, inputHeader.Input)
+ 		if err != nil {
+ 			dataErrorBuilder.AddErrorLocation(inputHeader.Label.ToHierarchyLabel())
+ 		}
+ 
+ 		rowBuilder.AddCells(value)
+ 	}
+ 
+ 	return isLastRow
+ }
+ 
+ /*
+ Persia の DB からフォームに入力されている値を取得する
+ ただし、Persia の DB にフォームの値が一つもない従業員については、社員名簿の値を初期値として CSV に載せたいため
+ 社員名簿から値を取得し、それを formValues の形に直して組み込んで返す.
+ */
+ func (u procedureCSVV3Usecase) getFormValuesByMember(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	memberIDs domain.MemberIDs,
+ 	csvDefs procedureform.CSVDefinitions,
+ ) (map[domain.MemberID]procedureform.FormValues, error) {
+ 	// 1. Persia の DB からフォームに入力されている値を取得
+ 	formValuesByMember, err := u.procedureFormValueRepo.GetFormValuesByProcedureIDAndMemberIDs(ctx, procedureID, memberIDs)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	// 2. 取得した formValuesByMember が memberIDs と同じ長さであれば、すでにすべての従業員についてフォームの値があるのでそのまま返す
+ 	if len(formValuesByMember) == len(memberIDs) {
+ 		return formValuesByMember, nil
+ 	}
+ 
+ 	// 3. フォームの値がひとつでもある従業員の一覧を取得
+ 	hasFormValueMemberIDs := slices.Collect(maps.Keys(formValuesByMember))
+ 
+ 	// 4. 今回のCSVダウンロードの対象となっている従業員との差集合をとり、まだフォームに値がひとつもない従業員を取得する
+ 	noFormValuesMemberIDs := util.SubtractionList(memberIDs, util.ToStringSlice(hasFormValueMemberIDs))
+ 
+ 	// 5. フォームに値がひとつもない従業員について、社員名簿の値を取得する
+ 	inputIDByUnitID := csvDefs.GetInputIDByUnitIDMap()
+ 	unitIDs := slices.Collect(maps.Keys(inputIDByUnitID))
+ 	unitValuesByMember, err := u.memberUnitValueRepo.FindUnitValues(ctx, noFormValuesMemberIDs, unitIDs)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	// 6. 5で取得した unitValuesByMember を formValues の形に直して formValuesByMember に挿入する.
+ 	for _, memberID := range noFormValuesMemberIDs {
+ 		domainMemberID := domain.MemberID(memberID)
+ 
+ 		unitValues, exists := unitValuesByMember[domainMemberID]
+ 		if exists {
+ 			formValues, err := procedureform.NewFormValuesFromMemberUnitValues(inputIDByUnitID, unitValues)
+ 			if err != nil {
+ 				return nil, perrors.AsIs(err)
+ 			}
+ 			formValuesByMember[domainMemberID] = formValues
+ 			continue
+ 		}
+ 
+ 		formValuesByMember[domainMemberID] = procedureform.FormValues{}
+ 	}
+ 
+ 	return formValuesByMember, nil
+ }
```

## apps/persia/app/usecases/procedure_csv_v3_upload.go
```diff
+ package usecases
+ 
+ import (
+ 	"bytes"
+ 	"context"
+ 	"errors"
+ 	"io"
+ 	"slices"
+ 	"unicode/utf8"
+ 
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
+ 	domainCsv "github.com/hrbrain/hrbrain/apps/persia/app/domain/csv"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/domain/procedureform/procedureformv2"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/perrors"
+ 	"github.com/hrbrain/hrbrain/apps/persia/app/lib/util"
+ )
+ 
+ func (u procedureCSVV3Usecase) SaveUploadedCSVValuesAndCreateUploadLog(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	versionDetail procedureform.ProcedureVersionDetail,
+ 	csvNumber procedureform.UploadCSVNumber,
+ 	csvFile io.Reader,
+ ) error {
+ 	saveValuesErr := u.saveUploadedCSVValues(ctx, procedureID, versionDetail, csvNumber, csvFile)
+ 	if saveValuesErr != nil {
+ 		isClientErr, createLogErr := u.createUploadErrorLog(ctx, procedureID, csvNumber, saveValuesErr)
+ 		if createLogErr != nil {
+ 			// ログの記録の際にもエラーが発生した場合は、元のエラーに結合して返す
+ 			combinedErr := errors.Join(saveValuesErr, createLogErr)
+ 			return perrors.Internal(combinedErr)
+ 		}
+ 
+ 		if isClientErr {
+ 			return perrors.BadRequest(saveValuesErr)
+ 		}
+ 
+ 		return perrors.AsIs(saveValuesErr)
+ 	}
+ 
+ 	return nil
+ }
+ 
+ // createUploadErrorLog は、CSVアップロード時に発生したエラーのログを記録する.
+ // 第1返り値は、エラーが 顧客側の操作に起因するエラー（DataError もしくは ReadingError） であるかどうかを示すブール値.
+ // 第2返り値は、ログの記録に失敗した場合のエラーを返す.
+ func (u procedureCSVV3Usecase) createUploadErrorLog(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	csvNumber procedureform.UploadCSVNumber,
+ 	saveValuesErr error,
+ ) (bool, error) {
+ 	if dataError := procedureform.AsCSVUploadDataError(saveValuesErr); dataError != nil {
+ 		if err := u.procedureCSVLogRepo.CreateCSVUploadLog(ctx, procedureID, csvNumber, dataError); err != nil {
+ 			return true, perrors.AsIs(err)
+ 		}
+ 		return true, nil
+ 	}
+ 
+ 	if readingError := procedureform.AsCSVUploadReadingError(saveValuesErr); readingError != nil {
+ 		if err := u.procedureCSVLogRepo.CreateCSVUploadLog(ctx, procedureID, csvNumber, readingError); err != nil {
+ 			return true, perrors.AsIs(err)
+ 		}
+ 		return true, nil
+ 	}
+ 
+ 	// 明示的にエラータイプを指定して返していないエラーは UnknownError として扱う
+ 	unknownError := procedureform.NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 		{ErrorType: domain.ProcedureCSVErrorTypeUnknownError},
+ 	})
+ 
+ 	if err := u.procedureCSVLogRepo.CreateCSVUploadLog(ctx, procedureID, csvNumber, unknownError); err != nil {
+ 		return false, perrors.AsIs(err)
+ 	}
+ 
+ 	return false, nil
+ }
+ 
+ func (u procedureCSVV3Usecase) saveUploadedCSVValues(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	versionDetail procedureform.ProcedureVersionDetail,
+ 	csvNumber procedureform.UploadCSVNumber,
+ 	csvFile io.Reader,
+ ) error {
+ 	csvDef, err := versionDetail.CSVDefinitions.GetCSVDefinition(csvNumber)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	buf := new(bytes.Buffer)
+ 	if _, err := io.Copy(buf, csvFile); err != nil {
+ 		return perrors.Internal(err)
+ 	}
+ 
+ 	if !utf8.Valid(buf.Bytes()) {
+ 		return procedureform.NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{ErrorType: domain.ProcedureCSVErrorTypeFileNotUTF8},
+ 		})
+ 	}
+ 
+ 	csv, err := domainCsv.NewCSVFromReader(buf)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	// CSVの一番左上に記載されている名前と、アップロードしようとしているCSV定義の名前が一致するか確認する
+ 	csvNameCell, err := csv.GetCell(0, 0)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	if csvNameCell.Value != csvDef.Name {
+ 		return procedureform.NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{ErrorType: domain.ProcedureCSVErrorTypeWrongPage},
+ 		})
+ 	}
+ 
+ 	procedure, err := u.procedureRepo.GetProcedureWithAllMemberIDsByID(ctx, procedureID.String())
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	if procedure.ProcedureStatus != domain.ProcedureStatusInProgress {
+ 		return procedureform.NewCSVUploadReadingError(domain.CSVUploadReadingErrorsToSaveV2{
+ 			{ErrorType: domain.ProcedureCSVErrorTypeProcedureIsNotInProgress},
+ 		})
+ 	}
+ 
+ 	procedureVersion, err := u.procedureRepo.FindProcedureVersionByProcedureID(ctx, procedureID.String())
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	members, err := u.memberRepo.GetMembersByIDs(ctx, procedure.MemberIDs)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	headerDetector, err := csvDef.HeaderDefinitions.NewCSVHeaderDetector(csv)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	rowWithMemberList, err := u.createRowWithMemberList(csv, members, headerDetector)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	filteredRowsByMember, err := u.filterRowsByMember(ctx, procedureID, rowWithMemberList.ByMember(), csvDef)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	form, err := procedureformv2.GetForm(procedureVersion.FormIDServer)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	// 従業員ごとの値の登録作業は、rowWithMemberList の並び順（ユーザーがアップロードしたCSVの並び）で行いたいため、
+ 	// ここで filteredRowsByMember（map）をrowsWithMemberList（スライス）へと変換する
+ 	rowsWithMemberList := filteredRowsByMember.ToRowsWithMember(rowWithMemberList)
+ 
+ 	memberIDs := make(domain.MemberIDs, 0, len(rowsWithMemberList))
+ 	for _, rowsWithMember := range rowsWithMemberList {
+ 		memberIDs = append(memberIDs, rowsWithMember.Member.ID)
+ 	}
+ 
+ 	formValuesByMember, err := u.procedureFormValueRepo.GetFormValuesByProcedureIDAndMemberIDs(ctx, procedureID, memberIDs)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	parsedFormValuesByMember, err := u.createParsedFormValuesAndValidate(rowsWithMemberList, form, formValuesByMember, headerDetector, csvDef.HeaderDefinitions)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	updatedInputIDs := headerDetector.GetInputIDsToBeDeletedOnCSVUpload(form)
+ 	err = u.tx.WithTx(ctx, func(ctx context.Context) error {
+ 		if err := u.procedureRepo.BulkDeleteFormValues(ctx, procedureID.String(), memberIDs, updatedInputIDs); err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 
+ 		if err := u.procedureRepo.BulkSaveFormValues(ctx, procedureID.String(), parsedFormValuesByMember); err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 
+ 		/*
+ 			ここでは初期値を消すだけ
+ 			この後で、依頼前に管理者が編集するか、依頼後に従業員が初めてフォームを開いた段階で初期値が改めて入るので、それでOK
+ 			CSVファイルには全ての項目の値が書かれている訳ではないので、ここで保存はしない方がいい
+ 		*/
+ 		if err := u.memberProcedureFormInitialValueRepo.BulkDeleteInitialValuesByInputIDs(ctx, procedureID, memberIDs, updatedInputIDs); err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 
+ 		if csvDef.ChangeStatusDocuments.NeedsUpdate() {
+ 			if err := u.updateDocumentStatuses(ctx, procedureID, procedureVersion, memberIDs, csvDef.ChangeStatusDocuments); err != nil {
+ 				return perrors.AsIs(err)
+ 			}
+ 		}
+ 
+ 		if len(csvDef.ChangeStatusPages) > 0 {
+ 			if err := u.updatePageStatuses(ctx, procedureID, procedureVersion, memberIDs, csvDef.ChangeStatusPages); err != nil {
+ 				return perrors.AsIs(err)
+ 			}
+ 		}
+ 
+ 		if err := u.procedureCSVLogRepo.CreateCSVUploadLog(ctx, procedureID, csvNumber, procedureform.NewCSVUploadResultSuccess()); err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 
+ 		return nil
+ 	})
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	return nil
+ }
+ 
+ func (u procedureCSVV3Usecase) createParsedFormValuesAndValidate(
+ 	rowsWithMemberList procedureform.RowsWithMemberList,
+ 	form procedureform.Form,
+ 	formValuesByMember map[domain.MemberID]procedureform.FormValues,
+ 	headerDetector procedureform.CSVHeaderDetector,
+ 	headerDefinitions procedureform.CSVHeaderDefinitions,
+ ) (map[domain.MemberID]domain.ParsedProcedureFormValues, error) {
+ 	identifierProvider := procedureform.NewCSVInputIdentifierProvider(form.GetSectionByInputID(), headerDetector, formValuesByMember)
+ 	parsedFormValuesByMember, err := u.createParsedFormValuesByMember(rowsWithMemberList, headerDetector, identifierProvider)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	validationErrorsByMember, err := u.validateValues(parsedFormValuesByMember, form)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	if len(validationErrorsByMember) > 0 {
+ 		dataError := u.convertToCSVUploadDataErrorFromValidationErrorsByMember(rowsWithMemberList, headerDefinitions, validationErrorsByMember)
+ 		return nil, perrors.AsIs(dataError)
+ 	}
+ 
+ 	return parsedFormValuesByMember, nil
+ }
+ 
+ func (u procedureCSVV3Usecase) convertToCSVUploadDataErrorFromValidationErrorsByMember(
+ 	rowsWithMemberList procedureform.RowsWithMemberList,
+ 	headerDefinitions procedureform.CSVHeaderDefinitions,
+ 	validationErrorsByMember map[domain.MemberID]procedureform.PageValidationErrors,
+ ) procedureform.CSVUploadDataError {
+ 	headerDefByInputID := headerDefinitions.ByInputID()
+ 	dataErrors := procedureform.NewCSVUploadDataError(domain.CSVUploadDataErrorsToSaveV2{})
+ 
+ 	// validationErrorsByMember は Map なので validationErrorsByMember で for loop を回すと順序が固定されない. そのため rowsWithMemberList で for loop を回している
+ 	for _, rowsWithMember := range rowsWithMemberList {
+ 		memberID := domain.MemberID(rowsWithMember.Member.ID)
+ 		validateErrors, ok := validationErrorsByMember[memberID]
+ 		if !ok {
+ 			continue
+ 		}
+ 		for _, validateError := range validateErrors {
+ 			/*
+ 				TODO:
+ 				validateErrorを CSVUploadDataErrorToSaveV2 に変換
+ 				そして変換したものを dataErrors に追加
+ 				dataErrors = dataErrors.AppendDetails(domain.CSVUploadDataErrorsToSaveV2{dataError})
+ 			*/
+ 
+ 			// 未使用の変数があることでエラーがあることを防ぐための一時的な措置. この2つの変数はこのTODO部分の処理で使う予定
+ 			_ = validateError
+ 			_ = headerDefByInputID
+ 		}
+ 	}
+ 
+ 	return dataErrors
+ }
+ 
+ // CSVを従業員ごとの構造体のリストに変換する処理
+ func (u procedureCSVV3Usecase) createRowWithMemberList(
+ 	csv domainCsv.CSV,
+ 	members domain.Members,
+ 	headerDetector procedureform.CSVHeaderDetector,
+ ) (procedureform.RowWithMemberList, error) {
+ 	csvMemberDetector, err := headerDetector.NewCSVMemberDetector(members)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	rowWithMemberList := procedureform.RowWithMemberList{}
+ 	for rowIdx, row := range csv.Rows {
+ 		if rowIdx < procedureform.HeaderRowCount {
+ 			continue
+ 		}
+ 		member, err := csvMemberDetector.DetectMemberByRow(row)
+ 		if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 		rowWithMemberList = append(rowWithMemberList, procedureform.RowWithMember{
+ 			Member: member,
+ 			Row:    row,
+ 		})
+ 	}
+ 
+ 	return rowWithMemberList, nil
+ }
+ 
+ // 引数の rowsByMember から、従業員ごとの手続きステータスや、一括確定処理中かなどを基準にメンバーを除外する
+ func (u procedureCSVV3Usecase) filterRowsByMember(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	rowsByMember procedureform.RowsByMember,
+ 	csvDef procedureform.CSVDefinition,
+ ) (procedureform.RowsByMember, error) {
+ 	memberIDs := rowsByMember.MemberIDs()
+ 	memberProcedureStatus, err := u.procedureRepo.GetMemberProcedureStatusMap(ctx, procedureID.String(), memberIDs)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	history, err := u.procedureBulkConfirmHistoryRepo.GetLatestBulkConfirmOperation(ctx, procedureID.String())
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	filter := procedureform.NewUploadMemberFilter(
+ 		csvDef.UploadMemberFilterFunc,
+ 		memberProcedureStatus,
+ 		history,
+ 	)
+ 
+ 	filteredMemberIDs, err := filter.FilterTargetMemberIDs(rowsByMember)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	filteredRowsByMember := rowsByMember.FilterByMemberIDs(filteredMemberIDs)
+ 
+ 	return filteredRowsByMember, nil
+ }
+ 
+ // rowsByMember から 手続きの値を保存するための parsedFormValuesByMember を構築する.
+ func (u procedureCSVV3Usecase) createParsedFormValuesByMember(
+ 	rowsWithMemberList procedureform.RowsWithMemberList,
+ 	headerDetector procedureform.CSVHeaderDetector,
+ 	identifierProvider procedureform.CSVInputIdentifierProvider,
+ ) (map[domain.MemberID]domain.ParsedProcedureFormValues, error) {
+ 	parsedFormValuesByMember := map[domain.MemberID]domain.ParsedProcedureFormValues{}
+ 	var entireDataError procedureform.CSVUploadDataError
+ 	for _, rowsWithMember := range rowsWithMemberList {
+ 		memberID := domain.MemberID(rowsWithMember.Member.ID)
+ 		rows := rowsWithMember.Rows
+ 		parsedFormValues, err := u.extractValuesByMember(memberID, rows, headerDetector, identifierProvider)
+ 
+ 		if dataErrorByMember := procedureform.AsCSVUploadDataError(err); dataErrorByMember != nil {
+ 			entireDataError = entireDataError.AppendDetails(dataErrorByMember.Details)
+ 			continue
+ 		} else if err != nil {
+ 			return nil, perrors.AsIs(err)
+ 		}
+ 
+ 		parsedFormValuesByMember[memberID] = parsedFormValues
+ 	}
+ 
+ 	if entireDataError.HasErrorDetails() {
+ 		return parsedFormValuesByMember, perrors.AsIs(entireDataError)
+ 	}
+ 
+ 	return parsedFormValuesByMember, nil
+ }
+ 
+ // rows から 手続きの値を保存するための parsedFormValues を構築する.
+ func (u procedureCSVV3Usecase) extractValuesByMember(
+ 	memberID domain.MemberID,
+ 	rows domainCsv.Rows,
+ 	headerDetector procedureform.CSVHeaderDetector,
+ 	identifierProvider procedureform.CSVInputIdentifierProvider,
+ ) (domain.ParsedProcedureFormValues, error) {
+ 	parsedFormValues := domain.ParsedProcedureFormValues{}
+ 	var dataError procedureform.CSVUploadDataError
+ 	for _, row := range rows {
+ 		for _, cell := range row.Cells {
+ 			// 従業員を特定する列はスキップする
+ 			if !headerDetector.IsInputHeader(cell.ColumnIndex) {
+ 				continue
+ 			}
+ 
+ 			// cellから対応する SectionID, GroupID, InputID を特定し取得
+ 			inputIdentifier, shouldSkip, err := identifierProvider.GetCSVInputIdentifier(memberID, cell, util.NewUUID)
+ 			if err != nil {
+ 				return nil, perrors.AsIs(err)
+ 			}
+ 
+ 			if shouldSkip {
+ 				continue
+ 			}
+ 
+ 			// CSVのセル上の値をDB登録用の値に変換する
+ 			values, err := u.extractValuesByCell(
+ 				cell,
+ 				inputIdentifier,
+ 				headerDetector,
+ 				parsedFormValues,
+ 			)
+ 			if dataErrorByCell := procedureform.AsCSVUploadDataError(err); dataErrorByCell != nil {
+ 				dataError = dataError.AppendDetails(dataErrorByCell.Details)
+ 				continue
+ 			} else if err != nil {
+ 				return nil, perrors.AsIs(err)
+ 			}
+ 			parsedFormValues = parsedFormValues.SetValues(
+ 				inputIdentifier.SectionID,
+ 				inputIdentifier.GroupID,
+ 				inputIdentifier.InputID,
+ 				values,
+ 			)
+ 		}
+ 	}
+ 
+ 	parsedFormValuesRemovedEmptyGroup := parsedFormValues.RemoveEmptyGroupFromParsedFormValues()
+ 
+ 	if dataError.HasErrorDetails() {
+ 		return parsedFormValuesRemovedEmptyGroup, perrors.AsIs(dataError)
+ 	}
+ 
+ 	return parsedFormValuesRemovedEmptyGroup, nil
+ }
+ 
+ // CSVのCellから値を抽出する.
+ func (u procedureCSVV3Usecase) extractValuesByCell(
+ 	cell domainCsv.Cell,
+ 	inputIdentifier procedureform.CSVInputIdentifier,
+ 	headerDetector procedureform.CSVHeaderDetector,
+ 	parsedFormValues domain.ParsedProcedureFormValues,
+ ) ([]string, error) {
+ 	// 現在の値を取得
+ 	currentValues := parsedFormValues.GetValues(
+ 		inputIdentifier.SectionID,
+ 		inputIdentifier.GroupID,
+ 		inputIdentifier.InputID,
+ 	)
+ 
+ 	// procedureform.InputValuesに詰め替える
+ 	currentInputValues := make(procedureform.InputValues, 0, len(currentValues))
+ 	for _, cv := range currentValues {
+ 		currentInputValues = append(currentInputValues, procedureform.NewInputValue(cv))
+ 	}
+ 
+ 	// headerDetector から InputHeader を取得
+ 	inputHeader, err := headerDetector.GetInputHeader(cell.ColumnIndex)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	// CSVに記載されている値 (cell.Value) を InputValueに変換する.
+ 	inputValues, err := inputHeader.Converter.ToInputValue(currentInputValues, cell.Value, inputHeader.Input)
+ 
+ 	// 返ってきたエラーが dataError であれば、そのdataErrorにはErrorTypeの情報しか入ってないので RowNumber などの情報を含める
+ 	if dataError := procedureform.AsCSVUploadDataError(err); dataError != nil {
+ 		for i := range dataError.Details {
+ 			dataError.Details[i].HierarchyLabel = inputHeader.Label.ToHierarchyLabel()
+ 			dataError.Details[i].RowNumber = int(cell.RowIndex.ToNumber())
+ 		}
+ 		return nil, perrors.AsIs(dataError)
+ 	} else if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	// stringのスライスに詰め直す
+ 	values := make([]string, 0, len(inputValues))
+ 	for _, v := range inputValues {
+ 		values = append(values, v.RawValue())
+ 	}
+ 
+ 	return values, nil
+ }
+ 
+ // 従業員ごとに値のバリデーションを行う
+ func (u procedureCSVV3Usecase) validateValues(
+ 	parsedFormValuesByMember map[domain.MemberID]domain.ParsedProcedureFormValues,
+ 	form procedureform.Form,
+ ) (map[domain.MemberID]procedureform.PageValidationErrors, error) {
+ 	inputIDsMap := form.GetInputIDsMap()
+ 	sectionByIDs := form.GetSectionIDsMap()
+ 	validationErrorsByMember := map[domain.MemberID]procedureform.PageValidationErrors{}
+ 	for member, parsedValues := range parsedFormValuesByMember {
+ 		for sectionID := range parsedValues {
+ 			section, exists := sectionByIDs[sectionID]
+ 			if !exists {
+ 				// 実装ミス以外でここに到達することはない
+ 				return nil, perrors.Internalf("section with ID %s not found in form", sectionID)
+ 			}
+ 			validationErrors, err := procedureform.ValidateValuesBySection(parsedValues, section, inputIDsMap, true, true, true)
+ 			if err != nil {
+ 				return nil, perrors.AsIs(err)
+ 			}
+ 			if len(validationErrors) > 0 {
+ 				validationErrorsByMember[member] = append(validationErrorsByMember[member], validationErrors...)
+ 			}
+ 		}
+ 	}
+ 
+ 	return validationErrorsByMember, nil
+ }
+ 
+ func (u procedureCSVV3Usecase) updateDocumentStatuses(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	version domain.ProcedureVersion,
+ 	memberIDs domain.MemberIDs,
+ 	changeStatusDocuments procedureform.ChangeStatusDocumentsOnCSVUpload,
+ ) error {
+ 	// 対象外の従業員をフィルタリングする
+ 	filteredMembers := make(domain.MemberIDs, 0, len(memberIDs))
+ 	if version.ProcedureTemplateID.Is年末調整() {
+ 		outOfScopeConditionDefs := procedureformv2.OutOfScopeDefMapForNenmatsuChousei[version.FormIDServer]
+ 		if len(outOfScopeConditionDefs) == 0 {
+ 			return nil
+ 		}
+ 		outOfScopeMembers, err := u.procedureRepo.GetOutOfScopeMembers(ctx, procedureID.String(), outOfScopeConditionDefs)
+ 		if err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 
+ 		outOfScopeMembersMap := make(map[string]struct{}, len(outOfScopeMembers))
+ 		for _, memberID := range outOfScopeMembers {
+ 			outOfScopeMembersMap[memberID] = struct{}{}
+ 		}
+ 
+ 		for _, memberID := range memberIDs {
+ 			if _, exist := outOfScopeMembersMap[memberID]; !exist {
+ 				filteredMembers = append(filteredMembers, memberID)
+ 			}
+ 		}
+ 	} else {
+ 		filteredMembers = append(filteredMembers, memberIDs...)
+ 	}
+ 
+ 	if len(filteredMembers) == 0 {
+ 		return nil
+ 	}
+ 
+ 	enabledDocumentIDs := make(domain.DocumentIDs, 0)
+ 	for _, dID := range changeStatusDocuments.EnabledDocumentIDs {
+ 		enabledDocumentIDs = append(enabledDocumentIDs, domain.DocumentID(dID.String()))
+ 	}
+ 
+ 	disabledDocumentIDs := make(domain.DocumentIDs, 0)
+ 	for _, dID := range changeStatusDocuments.DisabledDocumentIDs {
+ 		disabledDocumentIDs = append(disabledDocumentIDs, domain.DocumentID(dID.String()))
+ 	}
+ 
+ 	if len(enabledDocumentIDs) > 0 {
+ 		if err := u.procedureRepo.EnableMemberProcedureDocumentsByMemberIDs(ctx, procedureID.String(), filteredMembers, enabledDocumentIDs, true); err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 	}
+ 
+ 	if len(disabledDocumentIDs) > 0 {
+ 		if err := u.procedureRepo.EnableMemberProcedureDocumentsByMemberIDs(ctx, procedureID.String(), filteredMembers, disabledDocumentIDs, false); err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 	}
+ 
+ 	return nil
+ }
+ 
+ func (u procedureCSVV3Usecase) updatePageStatuses(
+ 	ctx context.Context,
+ 	procedureID procedureform.ProcedureID,
+ 	version domain.ProcedureVersion,
+ 	memberIDs domain.MemberIDs,
+ 	changeStatusPages procedureform.ChangeStatusPagesOnCSVUpload,
+ ) error {
+ 	statuses, err := u.procedureRepo.GetMemberProcedureFormPageStatusesByMemberIDs(ctx, procedureID.String(), memberIDs)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	form, err := procedureformv2.GetForm(version.FormIDServer)
+ 	if err != nil {
+ 		return perrors.AsIs(err)
+ 	}
+ 
+ 	for _, page := range changeStatusPages {
+ 		pageNumber, err := form.GetPageNumberByID(page.PageID)
+ 		if err != nil {
+ 			return perrors.AsIs(err)
+ 		}
+ 
+ 		memberIDsToUpdate := make(domain.MemberIDs, 0, len(memberIDs))
+ 
+ 		for _, memberID := range memberIDs {
+ 			pageStatus := domain.MemberProcedureFormPageStatusToDo
+ 
+ 			pageStatusByMemberID, ok := statuses[memberID]
+ 			if ok {
+ 				pageStatus = pageStatusByMemberID[uint8(pageNumber)]
+ 			}
+ 
+ 			if slices.Contains(page.PageStatusFrom, pageStatus) {
+ 				memberIDsToUpdate = append(memberIDsToUpdate, memberID)
+ 			}
+ 		}
+ 
+ 		if len(memberIDsToUpdate) > 0 {
+ 			if err := u.procedureRepo.UpdateMemberProcedureFormPageStatusByMemberIDs(ctx, procedureID.String(), memberIDsToUpdate, pageNumber, page.PageStatusTo); err != nil {
+ 				return perrors.AsIs(err)
+ 			}
+ 		}
+ 	}
+ 
+ 	return nil
+ }
```

## apps/persia/app/usecases/procedure_v2.go
```diff
+ 
+ func (u procedureUsecase) FindProcedureVersionDetailByProcedureID(ctx context.Context, procedureID procedureform.ProcedureID) (*procedureform.ProcedureVersionDetail, error) {
+ 	_, versionID, err := u.procedureRepo.GetProcedureTemplateIDAndVersionIDByProcedureID(ctx, procedureID)
+ 	if err != nil {
+ 		return nil, perrors.AsIs(err)
+ 	}
+ 
+ 	versionDetail, exists := u.templateRegistry.GetByVersionID(versionID)
+ 	if !exists {
+ 		return nil, nil
+ 	}
+ 
+ 	return &versionDetail, nil
+ }
```

## apps/persia/app/usecases/procedure_v2_test.go
```diff
+ 
+ func Test_procedureUsecase_FindProcedureVersionDetailByProcedureID(t *testing.T) {
+ 	templateID := util.NewFixedUUID("d1b2c3f4-5678-90ab-cdef-1234567890ab")
+ 	versionID := domain.ProcedureVersionID(1)
+ 
+ 	versionRegistry := procedureform.NewProcedureVersionRegistry(procedureform.ProcedureVersionDetail{
+ 		Version: versionID,
+ 	})
+ 	template := procedureform.ProcedureTemplate{
+ 		ID:              domain.ProcedureTemplateID(templateID.String()),
+ 		Name:            "test",
+ 		VersionRegistry: versionRegistry,
+ 	}
+ 
+ 	templateRegistry := procedureform.NewProcedureTemplateRegistry([]procedureform.ProcedureTemplate{template})
+ 
+ 	tests := []struct {
+ 		name             string
+ 		procedureID      procedureform.ProcedureID
+ 		templateRegistry procedureform.ProcedureTemplateRegistry
+ 		expect           func(ctx context.Context, procedureID procedureform.ProcedureID, mockHelper *testhelper.ProcedureUsecaseMockHelper)
+ 		want             *procedureform.ProcedureVersionDetail
+ 		errAssertion     assert.ErrorAssertionFunc
+ 	}{
+ 		{
+ 			name:             "success: version detail found",
+ 			templateRegistry: templateRegistry,
+ 			expect: func(ctx context.Context, procedureID procedureform.ProcedureID, mockHelper *testhelper.ProcedureUsecaseMockHelper) {
+ 				mockHelper.GetMockProcedureRepository().EXPECT().
+ 					GetProcedureTemplateIDAndVersionIDByProcedureID(ctx, procedureID).
+ 					Return(templateID, versionID, nil)
+ 			},
+ 			want: &procedureform.ProcedureVersionDetail{
+ 				Version: versionID,
+ 			},
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:             "success: version detail not found",
+ 			templateRegistry: templateRegistry,
+ 			expect: func(ctx context.Context, procedureID procedureform.ProcedureID, mockHelper *testhelper.ProcedureUsecaseMockHelper) {
+ 				mockHelper.GetMockProcedureRepository().EXPECT().
+ 					GetProcedureTemplateIDAndVersionIDByProcedureID(ctx, procedureID).
+ 					Return(uuid.Nil, domain.ProcedureVersionID(0), nil)
+ 			},
+ 			want:         nil,
+ 			errAssertion: assert.NoError,
+ 		},
+ 		{
+ 			name:             "failure: GetProcedureTemplateIDAndVersionIDByProcedureID error",
+ 			templateRegistry: templateRegistry,
+ 			expect: func(ctx context.Context, procedureID procedureform.ProcedureID, mockHelper *testhelper.ProcedureUsecaseMockHelper) {
+ 				mockHelper.GetMockProcedureRepository().EXPECT().
+ 					GetProcedureTemplateIDAndVersionIDByProcedureID(ctx, procedureID).
+ 					Return(uuid.Nil, domain.ProcedureVersionID(0), perrors.Internalf("GetProcedureTemplateIDAndVersionIDByProcedureID error"))
+ 			},
+ 			want:         nil,
+ 			errAssertion: testutils.AssertErrorCode(codes.Internal),
+ 		},
+ 	}
+ 	for _, tt := range tests {
+ 		t.Run(tt.name, func(t *testing.T) {
+ 			mockHelper := testhelper.NewProcedureUsecaseMockHelper(t)
+ 
+ 			ctx := t.Context()
+ 			tt.expect(ctx, tt.procedureID, mockHelper)
+ 
+ 			procedureUsecase := mockHelper.NewProcedureUsecase(tt.templateRegistry)
+ 			actual, err := procedureUsecase.FindProcedureVersionDetailByProcedureID(ctx, tt.procedureID)
+ 			tt.errAssertion(t, err)
+ 			assert.Equal(t, tt.want, actual)
+ 		})
+ 	}
+ }
```

## apps/persia/app/usecases/testhelper/mocks_repositories.gen.go
```diff
+ func (m *MockProcedureRepository) BulkDeleteFormValues(ctx context.Context, procedureID string, memberIDs []string, unitIDsToDelete []procedureform.InputID) error {
+ func (c *MockProcedureRepositoryBulkDeleteFormValuesCall) Do(f func(context.Context, string, []string, []procedureform.InputID) error) *MockProcedureRepositoryBulkDeleteFormValuesCall {
+ func (c *MockProcedureRepositoryBulkDeleteFormValuesCall) DoAndReturn(f func(context.Context, string, []string, []procedureform.InputID) error) *MockProcedureRepositoryBulkDeleteFormValuesCall {
+ func (m *MockProcedureRepository) BulkSaveFormValues(ctx context.Context, procedureID string, parsedValuesByMemberID map[domain.MemberID]domain.ParsedProcedureFormValues) error {
+ func (c *MockProcedureRepositoryBulkSaveFormValuesCall) Do(f func(context.Context, string, map[domain.MemberID]domain.ParsedProcedureFormValues) error) *MockProcedureRepositoryBulkSaveFormValuesCall {
+ func (c *MockProcedureRepositoryBulkSaveFormValuesCall) DoAndReturn(f func(context.Context, string, map[domain.MemberID]domain.ParsedProcedureFormValues) error) *MockProcedureRepositoryBulkSaveFormValuesCall {
+ func (m *MockProcedureRepository) GetMemberProcedureStatusMap(ctx context.Context, procedureID string, memberIDs []string) (map[domain.MemberID]domain.MemberProcedureStatus, error) {
+ 	ret0, _ := ret[0].(map[domain.MemberID]domain.MemberProcedureStatus)
+ func (c *MockProcedureRepositoryGetMemberProcedureStatusMapCall) Return(arg0 map[domain.MemberID]domain.MemberProcedureStatus, arg1 error) *MockProcedureRepositoryGetMemberProcedureStatusMapCall {
+ func (c *MockProcedureRepositoryGetMemberProcedureStatusMapCall) Do(f func(context.Context, string, []string) (map[domain.MemberID]domain.MemberProcedureStatus, error)) *MockProcedureRepositoryGetMemberProcedureStatusMapCall {
+ func (c *MockProcedureRepositoryGetMemberProcedureStatusMapCall) DoAndReturn(f func(context.Context, string, []string) (map[domain.MemberID]domain.MemberProcedureStatus, error)) *MockProcedureRepositoryGetMemberProcedureStatusMapCall {
+ // BulkDeleteInitialValuesByInputIDs mocks base method.
+ func (m *MockMemberProcedureFormInitialValueRepository) BulkDeleteInitialValuesByInputIDs(ctx context.Context, procedureID procedureform.ProcedureID, memberIDs domain.MemberIDs, inputIDs []procedureform.InputID) error {
+ 	m.ctrl.T.Helper()
+ 	ret := m.ctrl.Call(m, "BulkDeleteInitialValuesByInputIDs", ctx, procedureID, memberIDs, inputIDs)
+ 	ret0, _ := ret[0].(error)
+ 	return ret0
+ }
+ 
+ // BulkDeleteInitialValuesByInputIDs indicates an expected call of BulkDeleteInitialValuesByInputIDs.
+ func (mr *MockMemberProcedureFormInitialValueRepositoryMockRecorder) BulkDeleteInitialValuesByInputIDs(ctx, procedureID, memberIDs, inputIDs any) *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall {
+ 	mr.mock.ctrl.T.Helper()
+ 	call := mr.mock.ctrl.RecordCallWithMethodType(mr.mock, "BulkDeleteInitialValuesByInputIDs", reflect.TypeOf((*MockMemberProcedureFormInitialValueRepository)(nil).BulkDeleteInitialValuesByInputIDs), ctx, procedureID, memberIDs, inputIDs)
+ 	return &MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall{Call: call}
+ }
+ 
+ // MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall wrap *gomock.Call
+ type MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall struct {
+ 	*gomock.Call
+ }
+ 
+ // Return rewrite *gomock.Call.Return
+ func (c *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall) Return(arg0 error) *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall {
+ 	c.Call = c.Call.Return(arg0)
+ 	return c
+ }
+ 
+ // Do rewrite *gomock.Call.Do
+ func (c *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall) Do(f func(context.Context, procedureform.ProcedureID, domain.MemberIDs, []procedureform.InputID) error) *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall {
+ 	c.Call = c.Call.Do(f)
+ 	return c
+ }
+ 
+ // DoAndReturn rewrite *gomock.Call.DoAndReturn
+ func (c *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall) DoAndReturn(f func(context.Context, procedureform.ProcedureID, domain.MemberIDs, []procedureform.InputID) error) *MockMemberProcedureFormInitialValueRepositoryBulkDeleteInitialValuesByInputIDsCall {
+ 	c.Call = c.Call.DoAndReturn(f)
+ 	return c
+ }
+ 
```

## apps/persia/schema/persia-api.yaml
```diff
+           $ref: '#/components/schemas/UUID'
+           $ref: '#/components/schemas/UUID'
+           $ref: '#/components/schemas/UUID'
```

