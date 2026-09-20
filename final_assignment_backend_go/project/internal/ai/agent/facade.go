package agent

import (
	"encoding/json"

	"final_assignment_backend_go/project/internal/domain"
	"final_assignment_backend_go/project/internal/service/appeal"
	"final_assignment_backend_go/project/internal/service/offense"
	"final_assignment_backend_go/project/internal/service/shared"

	"gorm.io/gorm"
)

type DomainFacade struct {
	DB      *gorm.DB
	Offense *offense.OffenseInformationService
	Fine    *offense.FineInformationService
	Appeal  *appeal.AppealManagementService
}

func (f *DomainFacade) ResolveDriverID(username string) *int {
	if f == nil || f.DB == nil {
		return nil
	}
	id, ok := shared.RequesterDriverID(f.DB, username)
	if !ok {
		return nil
	}
	return &id
}

func (f *DomainFacade) ListOffenses(ctx Context, driverID *int) ([]map[string]any, error) {
	if ctx.Elevated && driverID != nil && f.Offense != nil {
		// admin filter uses requester list then filter
		items, err := f.Offense.ListForRequester(ctx.Username, true)
		if err != nil {
			return nil, err
		}
		filtered := make([]domain.OffenseInformation, 0)
		for _, item := range items {
			if item.DriverID != nil && *item.DriverID == *driverID {
				filtered = append(filtered, item)
			}
		}
		return toMaps(filtered), nil
	}
	items, err := f.Offense.ListForRequester(ctx.Username, ctx.Elevated)
	if err != nil {
		return nil, err
	}
	return toMaps(items), nil
}

func (f *DomainFacade) CreateOffense(ctx Context, args map[string]any) (map[string]any, error) {
	var record domain.OffenseInformation
	raw, _ := json.Marshal(args)
	_ = json.Unmarshal(raw, &record)
	record.CreatedBy = ctx.Username
	if err := f.Offense.CreateOffense(&record); err != nil {
		return nil, err
	}
	return toMap(record), nil
}

func (f *DomainFacade) ListFines(ctx Context, driverID *int) ([]map[string]any, error) {
	if ctx.Elevated && driverID != nil {
		items, err := f.Fine.GetFinesByDriverID(*driverID)
		if err != nil {
			return nil, err
		}
		return toMaps(items), nil
	}
	items, err := f.Fine.ListForRequester(ctx.Username, ctx.Elevated)
	if err != nil {
		return nil, err
	}
	return toMaps(items), nil
}

func (f *DomainFacade) CreateFine(ctx Context, args map[string]any) (map[string]any, error) {
	var record domain.FineInformation
	raw, _ := json.Marshal(args)
	_ = json.Unmarshal(raw, &record)
	if err := f.Fine.CreateFine(&record); err != nil {
		return nil, err
	}
	return toMap(record), nil
}

func (f *DomainFacade) ListAppeals(ctx Context, driverID *int) ([]map[string]any, error) {
	items, err := f.Appeal.ListForRequester(ctx.Username, ctx.Elevated)
	if err != nil {
		return nil, err
	}
	if ctx.Elevated && driverID != nil {
		filtered := make([]domain.AppealManagement, 0)
		for _, item := range items {
			if item.DriverID != nil && *item.DriverID == *driverID {
				filtered = append(filtered, item)
			}
		}
		return toMaps(filtered), nil
	}
	return toMaps(items), nil
}

func (f *DomainFacade) CreateAppeal(ctx Context, args map[string]any) (map[string]any, error) {
	var record domain.AppealManagement
	raw, _ := json.Marshal(args)
	_ = json.Unmarshal(raw, &record)
	if ctx.DriverID != nil {
		record.DriverID = ctx.DriverID
	}
	if err := f.Appeal.CreateAppeal(&record); err != nil {
		return nil, err
	}
	return toMap(record), nil
}

func toMaps[T any](items []T) []map[string]any {
	out := make([]map[string]any, 0, len(items))
	for _, item := range items {
		out = append(out, toMap(item))
	}
	return out
}

func toMap(value any) map[string]any {
	raw, err := json.Marshal(value)
	if err != nil {
		return map[string]any{}
	}
	out := map[string]any{}
	_ = json.Unmarshal(raw, &out)
	return out
}
