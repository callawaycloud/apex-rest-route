@isTest
public class RestRouteTestRoutes {
    //TOP LEVEL ROUTE

    // could be used to support multiple versions
    public class APIEntryRoute extends RestRoute {
        protected override Map<String, RestRoute> getNextRouteMap() {
            //two ways to support multiple versions
            //  1. Return different routers based on this.resourceId
            //  2. Pass this.resourceId into children routes and let each route deal
            //      with how to respond to different versions
            return new Map<String, RestRoute>{
                'companies' => new CompanyRoute(),
                'employees' => new CompanyEmployeeRoute(null),
                'other' => new MultipathRoute()
            };
        }
    }

    // other/foo/
    public class MultipathRoute extends RestRoute {
        protected override boolean hasResource() {
            return false;
        }
        protected override Map<String, RestRoute> getNextRouteMap() {
            return new Map<String, RestRoute>{ 'foo' => new FooRoute() };
        }
    }

    public class FooRoute extends RestRoute {
        public override Object doGet() {
            response.responseBody = Blob.valueOf('foo');
            return null;
        }
    }

    // companies/:companyId?
    public class CompanyRoute extends RestRoute {
        public override Object doGet() {
            Company[] companies = getCompanies();
            if (!String.isEmpty(this.resourceId)) {
                Company c = (Company) getEntityById(this.resourceId, companies);
                if (this.request.params.containsKey('expand')) {
                    return expandResource(c);
                }
                return c;
            }

            if (this.request.params.containsKey('expand')) {
                List<Map<String, Object>> expandedResponse = new List<Map<String, Object>>();
                for (Company c : companies) {
                    this.resourceId = c.id;
                    expandedResponse.add(expandResource(c));
                }
                return expandedResponse;
            }

            return companies;
        }

        protected override Map<String, RestRoute> getNextRouteMap() {
            return new Map<String, RestRoute>{
                'locations' => new CompanyLocationRoute(this.resourceId),
                'employees' => new CompanyEmployeeRoute(this.resourceId)
            };
        }
    }

    // Company Locations Route
    //   companies/:companyId/locations/:locationId?
    public class CompanyLocationRoute extends RestRoute {
        private String companyId;

        public CompanyLocationRoute(String companyId) {
            this.companyId = companyId;
        }

        protected override Object doGet() {
            //filter down by company
            CompanyEntity[] companyLocations = getEntitiesByCompany(companyId, LOCATIONS);

            if (!String.isEmpty(this.resourceId)) {
                return getEntityById(this.resourceId, companyLocations);
            }
            return companyLocations;
        }
    }

    // Company Locations Route
    //   api/v1/employees?companyId=:companyId
    //   api/v1/companies/:companyId/employees/:employeeId?
    public class CompanyEmployeeRoute extends RestRoute {
        private String companyId;

        public CompanyEmployeeRoute(String companyId) {
            this.companyId = companyId;
        }

        protected override Object doGet() {
            //support for /api/v1/employees?companyId=:companyId
            if (this.companyId == null && this.request.params.containsKey('companyId')) {
                this.companyId = this.request.params.get('companyId');
            }

            //optionally filter down by company
            CompanyEntity[] companyEmployees = EMPLOYEES;
            if (this.companyId != null) {
                companyEmployees = getEntitiesByCompany(this.companyId, EMPLOYEES);
            }

            if (!String.isEmpty(this.resourceId)) {
                return getEntityById(this.resourceId, companyEmployees);
            }

            if (this.request.params.containsKey('role')) {
                String roleFilter = this.request.params.get('role');
                for (Integer i = companyEmployees.size() - 1; i >= 0; i--) {
                    CompanyEmployee employee = (CompanyEmployee) companyEmployees[i];
                    if (employee.role != roleFilter) {
                        companyEmployees.remove(i);
                    }
                }
            }
            return companyEmployees;
        }
    }

    // DATA MODEL & RETRIEVAL HELPERS
    public virtual class IdEntity {
        public string id;
        public IdEntity(String id) {
            this.id = id;
        }
    }

    public class Company extends IdEntity {
        public String name;
        public Company(String id, String name) {
            super(id);
            this.name = name;
        }
    }

    public virtual class CompanyEntity extends IdEntity {
        public String companyId;
        public CompanyEntity(String companyId, String id) {
            super(id);
            this.companyId = companyId;
        }
    }

    public class CompanyLocation extends CompanyEntity {
        public String name;
        public CompanyLocation(String companyId, String id, String name) {
            super(companyId, id);
            this.name = name;
        }
    }

    public class CompanyEmployee extends CompanyEntity {
        public String name;
        public String role;
        public CompanyEmployee(String companyId, String id, String name, String role) {
            super(companyId, id);
            this.name = name;
            this.role = role;
        }
    }

    // === DATA + HELPERS ===

    static Company[] getCompanies() {
        return COMPANIES;
    }

    static final Company[] COMPANIES = new List<Company>{ new Company('c-1', 'Acme'), new Company('c-2', 'Stark Industries') };

    static final CompanyLocation[] LOCATIONS = new List<CompanyLocation>{
        new CompanyLocation('c-1', 'l-1', 'Desert'),
        new CompanyLocation('c-1', 'l-2', 'NYC'),
        new CompanyLocation('c-2', 'l-3', 'LA')
    };

    static final CompanyEmployee[] EMPLOYEES = new List<CompanyEmployee>{
        new CompanyEmployee('c-1', 'e-1', 'Daffy Duck', 'CEO'),
        new CompanyEmployee('c-1', 'e-2', 'Bugs Bunny', 'CFO'),
        new CompanyEmployee('c-2', 'e-3', 'Iron Man', 'CEO'),
        new CompanyEmployee('c-2', 'e-4', 'Tony Stark', 'CEO'),
        new CompanyEmployee('c-2', 'e-5', 'Test Dummy', 'QA')
    };

    private static IdEntity getEntityById(String id, IdEntity[] entities) {
        for (IdEntity c : entities) {
            if (c.id == id) {
                return c;
            }
        }
        throw new RestRoute.EntityNotFoundException(null, id);
    }

    private static CompanyEntity[] getEntitiesByCompany(String companyId, CompanyEntity[] entities) {
        CompanyEntity[] companyEntities = new List<CompanyEntity>{};
        for (CompanyEntity entity : entities) {
            if (entity.companyId == companyId) {
                companyEntities.add(entity);
            }
        }
        return companyEntities;
    }
}
