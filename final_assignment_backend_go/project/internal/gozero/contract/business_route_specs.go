package contract

import "net/http"

func BusinessRouteSpecs() []RouteSpec {
	routes := []RouteSpec{}
	routes = append(routes, DriverRouteSpecs()...)
	routes = append(routes, OffenseRouteSpecs()...)
	routes = append(routes, OffenseTypeRouteSpecs()...)
	routes = append(routes, FineRouteSpecs()...)
	routes = append(routes, DeductionRouteSpecs()...)
	routes = append(routes, AppealRouteSpecs()...)
	routes = append(routes, PaymentRouteSpecs()...)
	routes = append(routes, ProgressRouteSpecs()...)
	routes = append(routes, TrafficViolationRouteSpecs()...)
	routes = append(routes, WorkflowRouteSpecs()...)
	routes = append(routes, OffenseDetailsViewRouteSpecs()...)
	return routes
}

func DriverRouteSpecs() []RouteSpec {
	return []RouteSpec{
		driverRoute(http.MethodPost, "/api/drivers", "create", "@PostMapping"),
		driverRoute(http.MethodGet, "/api/drivers", "list", "@GetMapping"),
		driverRoute(http.MethodGet, "/api/drivers/search/id-card", "searchByIdCard", `@GetMapping("/search/id-card")`),
		driverRoute(http.MethodGet, "/api/drivers/search/license", "searchByLicense", `@GetMapping("/search/license")`),
		driverRoute(http.MethodGet, "/api/drivers/search/name", "searchByName", `@GetMapping("/search/name")`),
		driverRoute(http.MethodGet, "/api/drivers/search", "searchDrivers", `@GetMapping("/search")`),
		driverRoute(http.MethodPut, "/api/drivers/:driverId", "update", `@PutMapping("/{driverId}")`),
		driverRoute(http.MethodDelete, "/api/drivers/:driverId", "delete", `@DeleteMapping("/{driverId}")`),
		driverRoute(http.MethodGet, "/api/drivers/:driverId", "get", `@GetMapping("/{driverId}")`),
	}
}

func OffenseRouteSpecs() []RouteSpec {
	return []RouteSpec{
		offenseRoute(http.MethodPost, "/api/offenses", "create", "@PostMapping"),
		offenseRoute(http.MethodGet, "/api/offenses", "list", "@GetMapping"),
		offenseRoute(http.MethodGet, "/api/offenses/driver/:driverId", "byDriver", `@GetMapping("/driver/{driverId}")`),
		offenseRoute(http.MethodGet, "/api/offenses/vehicle/:vehicleId", "byVehicle", `@GetMapping("/vehicle/{vehicleId}")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/code", "searchByCode", `@GetMapping("/search/code")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/status", "searchByStatus", `@GetMapping("/search/status")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/time-range", "searchByTimeRange", `@GetMapping("/search/time-range")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/number", "searchByNumber", `@GetMapping("/search/number")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/location", "searchByLocation", `@GetMapping("/search/location")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/province", "searchByProvince", `@GetMapping("/search/province")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/city", "searchByCity", `@GetMapping("/search/city")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/notification", "searchByNotification", `@GetMapping("/search/notification")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/agency", "searchByAgency", `@GetMapping("/search/agency")`),
		offenseRoute(http.MethodGet, "/api/offenses/search/fine-range", "searchByFineRange", `@GetMapping("/search/fine-range")`),
		offenseRoute(http.MethodGet, "/api/offenses/:offenseId/details", "getDetails", `@GetMapping("/{offenseId}/details")`),
		offenseRoute(http.MethodPut, "/api/offenses/:offenseId", "update", `@PutMapping("/{offenseId}")`),
		offenseRoute(http.MethodDelete, "/api/offenses/:offenseId", "delete", `@DeleteMapping("/{offenseId}")`),
		offenseRoute(http.MethodGet, "/api/offenses/:offenseId", "get", `@GetMapping("/{offenseId}")`),
	}
}

func OffenseTypeRouteSpecs() []RouteSpec {
	return []RouteSpec{
		offenseTypeRoute(http.MethodPost, "/api/offense-types", "create", "@PostMapping"),
		offenseTypeRoute(http.MethodGet, "/api/offense-types", "list", "@GetMapping"),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/code/prefix", "searchByCodePrefix", `@GetMapping("/search/code/prefix")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/code/fuzzy", "searchByCodeFuzzy", `@GetMapping("/search/code/fuzzy")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/name/prefix", "searchByNamePrefix", `@GetMapping("/search/name/prefix")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/name/fuzzy", "searchByNameFuzzy", `@GetMapping("/search/name/fuzzy")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/category", "searchByCategory", `@GetMapping("/search/category")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/severity", "searchBySeverity", `@GetMapping("/search/severity")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/status", "searchByStatus", `@GetMapping("/search/status")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/fine-range", "searchByFineRange", `@GetMapping("/search/fine-range")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/search/points-range", "searchByPointsRange", `@GetMapping("/search/points-range")`),
		offenseTypeRoute(http.MethodPut, "/api/offense-types/:typeId", "update", `@PutMapping("/{typeId}")`),
		offenseTypeRoute(http.MethodDelete, "/api/offense-types/:typeId", "delete", `@DeleteMapping("/{typeId}")`),
		offenseTypeRoute(http.MethodGet, "/api/offense-types/:typeId", "get", `@GetMapping("/{typeId}")`),
	}
}

func FineRouteSpecs() []RouteSpec {
	return []RouteSpec{
		fineRoute(http.MethodPost, "/api/fines", "create", "@PostMapping"),
		fineRoute(http.MethodGet, "/api/fines", "list", "@GetMapping"),
		fineRoute(http.MethodGet, "/api/fines/offense/:offenseId", "byOffense", `@GetMapping("/offense/{offenseId}")`),
		fineRoute(http.MethodGet, "/api/fines/driver/:driverId", "byDriver", `@GetMapping("/driver/{driverId}")`),
		fineRoute(http.MethodGet, "/api/fines/search/handler", "searchByHandler", `@GetMapping("/search/handler")`),
		fineRoute(http.MethodGet, "/api/fines/search/status", "searchByPaymentStatus", `@GetMapping("/search/status")`),
		fineRoute(http.MethodGet, "/api/fines/search/date-range", "searchByDateRange", `@GetMapping("/search/date-range")`),
		fineRoute(http.MethodPut, "/api/fines/:fineId", "update", `@PutMapping("/{fineId}")`),
		fineRoute(http.MethodDelete, "/api/fines/:fineId", "delete", `@DeleteMapping("/{fineId}")`),
		fineRoute(http.MethodGet, "/api/fines/:fineId", "get", `@GetMapping("/{fineId}")`),
	}
}

func DeductionRouteSpecs() []RouteSpec {
	return []RouteSpec{
		deductionRoute(http.MethodPost, "/api/deductions", "create", "@PostMapping"),
		deductionRoute(http.MethodGet, "/api/deductions", "list", "@GetMapping"),
		deductionRoute(http.MethodGet, "/api/deductions/driver/:driverId", "byDriver", `@GetMapping("/driver/{driverId}")`),
		deductionRoute(http.MethodGet, "/api/deductions/offense/:offenseId", "byOffense", `@GetMapping("/offense/{offenseId}")`),
		deductionRoute(http.MethodGet, "/api/deductions/search/handler", "searchByHandler", `@GetMapping("/search/handler")`),
		deductionRoute(http.MethodGet, "/api/deductions/search/status", "searchByStatus", `@GetMapping("/search/status")`),
		deductionRoute(http.MethodGet, "/api/deductions/search/time-range", "searchByTimeRange", `@GetMapping("/search/time-range")`),
		deductionRoute(http.MethodPut, "/api/deductions/:deductionId", "update", `@PutMapping("/{deductionId}")`),
		deductionRoute(http.MethodDelete, "/api/deductions/:deductionId", "delete", `@DeleteMapping("/{deductionId}")`),
		deductionRoute(http.MethodGet, "/api/deductions/:deductionId", "get", `@GetMapping("/{deductionId}")`),
	}
}

func AppealRouteSpecs() []RouteSpec {
	return []RouteSpec{
		appealRoute(http.MethodPost, "/api/appeals", "createAppeal", "@PostMapping"),
		appealRoute(http.MethodGet, "/api/appeals", "listAppeals", "@GetMapping"),
		appealRoute(http.MethodGet, "/api/appeals/my", "getMyAppeals", `@GetMapping("/my")`),
		appealRoute(http.MethodGet, "/api/appeals/search/number/prefix", "searchByNumberPrefix", `@GetMapping("/search/number/prefix")`),
		appealRoute(http.MethodGet, "/api/appeals/search/number/fuzzy", "searchByNumberFuzzy", `@GetMapping("/search/number/fuzzy")`),
		appealRoute(http.MethodGet, "/api/appeals/search/appellant/name/prefix", "searchByAppellantNamePrefix", `@GetMapping("/search/appellant/name/prefix")`),
		appealRoute(http.MethodGet, "/api/appeals/search/appellant/name/fuzzy", "searchByAppellantNameFuzzy", `@GetMapping("/search/appellant/name/fuzzy")`),
		appealRoute(http.MethodGet, "/api/appeals/search/appellant/id-card", "searchByAppellantIdCard", `@GetMapping("/search/appellant/id-card")`),
		appealRoute(http.MethodGet, "/api/appeals/search/acceptance-status", "searchByAcceptanceStatus", `@GetMapping("/search/acceptance-status")`),
		appealRoute(http.MethodGet, "/api/appeals/search/process-status", "searchByProcessStatus", `@GetMapping("/search/process-status")`),
		appealRoute(http.MethodGet, "/api/appeals/search/time-range", "searchByTimeRange", `@GetMapping("/search/time-range")`),
		appealRoute(http.MethodGet, "/api/appeals/search/handler", "searchByHandler", `@GetMapping("/search/handler")`),
		appealRoute(http.MethodGet, "/api/appeals/reviews", "listReviews", `@GetMapping("/reviews")`),
		appealRoute(http.MethodGet, "/api/appeals/reviews/search/reviewer", "searchReviewsByReviewer", `@GetMapping("/reviews/search/reviewer")`),
		appealRoute(http.MethodGet, "/api/appeals/reviews/search/reviewer-dept", "searchReviewsByReviewerDept", `@GetMapping("/reviews/search/reviewer-dept")`),
		appealRoute(http.MethodGet, "/api/appeals/reviews/search/time-range", "searchReviewsByTimeRange", `@GetMapping("/reviews/search/time-range")`),
		appealRoute(http.MethodGet, "/api/appeals/reviews/count", "countReviews", `@GetMapping("/reviews/count")`),
		appealRoute(http.MethodPut, "/api/appeals/reviews/:reviewId", "updateReview", `@PutMapping("/reviews/{reviewId}")`),
		appealRoute(http.MethodDelete, "/api/appeals/reviews/:reviewId", "deleteReview", `@DeleteMapping("/reviews/{reviewId}")`),
		appealRoute(http.MethodGet, "/api/appeals/reviews/:reviewId", "getReview", `@GetMapping("/reviews/{reviewId}")`),
		appealRoute(http.MethodPost, "/api/appeals/:appealId/reviews", "createReview", `@PostMapping("/{appealId}/reviews")`),
		appealRoute(http.MethodPut, "/api/appeals/:appealId", "updateAppeal", `@PutMapping("/{appealId}")`),
		appealRoute(http.MethodDelete, "/api/appeals/:appealId", "deleteAppeal", `@DeleteMapping("/{appealId}")`),
		appealRoute(http.MethodGet, "/api/appeals/:appealId", "getAppeal", `@GetMapping("/{appealId}")`),
	}
}

func PaymentRouteSpecs() []RouteSpec {
	return []RouteSpec{
		paymentRoute(http.MethodPost, "/api/payments", "createPayment", "@PostMapping"),
		paymentRoute(http.MethodGet, "/api/payments", "listPayments", "@GetMapping"),
		paymentRoute(http.MethodGet, "/api/payments/fine/:fineId", "findByFine", `@GetMapping("/fine/{fineId}")`),
		paymentRoute(http.MethodGet, "/api/payments/driver/:driverId", "findByDriver", `@GetMapping("/driver/{driverId}")`),
		paymentRoute(http.MethodPost, "/api/payments/driver/:driverId", "createDriverPayment", `@PostMapping("/driver/{driverId}")`),
		paymentRoute(http.MethodGet, "/api/payments/search/payer", "searchByPayer", `@GetMapping("/search/payer")`),
		paymentRoute(http.MethodGet, "/api/payments/search/status", "searchByStatus", `@GetMapping("/search/status")`),
		paymentRoute(http.MethodGet, "/api/payments/search/transaction", "searchByTransaction", `@GetMapping("/search/transaction")`),
		paymentRoute(http.MethodGet, "/api/payments/search/payment-number", "searchByPaymentNumber", `@GetMapping("/search/payment-number")`),
		paymentRoute(http.MethodGet, "/api/payments/search/payer-name", "searchByPayerName", `@GetMapping("/search/payer-name")`),
		paymentRoute(http.MethodGet, "/api/payments/search/payment-method", "searchByPaymentMethod", `@GetMapping("/search/payment-method")`),
		paymentRoute(http.MethodGet, "/api/payments/search/payment-channel", "searchByPaymentChannel", `@GetMapping("/search/payment-channel")`),
		paymentRoute(http.MethodGet, "/api/payments/search/time-range", "searchByTimeRange", `@GetMapping("/search/time-range")`),
		paymentRoute(http.MethodPut, "/api/payments/:paymentId/status/:state", "updatePaymentStatus", `@PutMapping("/{paymentId}/status/{state}")`),
		paymentRoute(http.MethodPut, "/api/payments/:paymentId", "updatePayment", `@PutMapping("/{paymentId}")`),
		paymentRoute(http.MethodDelete, "/api/payments/:paymentId", "deletePayment", `@DeleteMapping("/{paymentId}")`),
		paymentRoute(http.MethodGet, "/api/payments/:paymentId", "getPayment", `@GetMapping("/{paymentId}")`),
	}
}

func ProgressRouteSpecs() []RouteSpec {
	return []RouteSpec{
		progressRoute(http.MethodPost, "/api/progress", "create", "@PostMapping"),
		progressRoute(http.MethodGet, "/api/progress", "list", "@GetMapping"),
		progressRoute(http.MethodGet, "/api/progress/timeRange", "getByTimeRange", `@GetMapping("/timeRange")`),
		progressRoute(http.MethodGet, "/api/progress/status", "getByStatus", `@GetMapping("/status")`),
		progressRoute(http.MethodGet, "/api/progress/status/:status", "getByStatusPathDeprecated", `@GetMapping("/status/{status}")`),
		progressRoute(http.MethodGet, "/api/progress/idempotency/:key", "getByIdempotencyKey", `@GetMapping("/idempotency/{key}")`),
		progressRoute(http.MethodPut, "/api/progress/:historyId", "update", `@PutMapping("/{historyId}")`),
		progressRoute(http.MethodDelete, "/api/progress/:historyId", "delete", `@DeleteMapping("/{historyId}")`),
		progressRoute(http.MethodGet, "/api/progress/:historyId", "get", `@GetMapping("/{historyId}")`),
	}
}

func TrafficViolationRouteSpecs() []RouteSpec {
	return []RouteSpec{
		trafficViolationRoute(http.MethodGet, "/api/violations", "listViolations", "@GetMapping"),
		trafficViolationRoute(http.MethodGet, "/api/violations/status", "violationByStatus", `@GetMapping("/status")`),
		trafficViolationRoute(http.MethodGet, "/api/violations/:offenseId", "violationDetails", `@GetMapping("/{offenseId}")`),
	}
}

func WorkflowRouteSpecs() []RouteSpec {
	return []RouteSpec{
		workflowRoute(http.MethodPost, "/api/workflow/offenses/:offenseId/events/:event", "triggerOffenseEvent", `@PostMapping("/offenses/{offenseId}/events/{event}")`),
		workflowRoute(http.MethodPost, "/api/workflow/payments/:paymentId/events/:event", "triggerPaymentEvent", `@PostMapping("/payments/{paymentId}/events/{event}")`),
		workflowRoute(http.MethodPost, "/api/workflow/appeals/:appealId/events/:event", "triggerAppealEvent", `@PostMapping("/appeals/{appealId}/events/{event}")`),
	}
}

func OffenseDetailsViewRouteSpecs() []RouteSpec {
	return []RouteSpec{
		offenseDetailsViewRoute(http.MethodGet, "/api/view/offenses/:offenseId", "getDetails", `@GetMapping("/{offenseId}")`),
	}
}

func driverRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "drivers", operation, "DriverInformationController", mapping)
}

func offenseRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "offenses", operation, "OffenseInformationController", mapping)
}

func offenseTypeRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "offense-types", operation, "OffenseTypeController", mapping)
}

func fineRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "fines", operation, "FineInformationController", mapping)
}

func deductionRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "deductions", operation, "DeductionInformationController", mapping)
}

func appealRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "appeals", operation, "AppealManagementController", mapping)
}

func paymentRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "payments", operation, "PaymentRecordController", mapping)
}

func progressRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "progress", operation, "ProgressItemController", mapping)
}

func trafficViolationRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "violations-dashboard", operation, "TrafficViolationController", mapping)
}

func workflowRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "workflow", operation, "WorkflowController", mapping)
}

func offenseDetailsViewRoute(method, path, operation, mapping string) RouteSpec {
	return routeSpec(method, path, "offense-details-view", operation, "OffenseDetailsController", mapping)
}
