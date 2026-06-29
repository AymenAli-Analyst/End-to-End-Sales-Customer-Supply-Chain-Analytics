-- Placeholder Dimension Tables for Foreign Key references
-- Note: Assuming standard primary key types matching the foreign keys in Dim_Fact_Sales.

CREATE TABLE dbo.Dim_Store (
    StoreID NVARCHAR(50) PRIMARY KEY NOT NULL,
    StoreName NVARCHAR(100) NULL,
    StoreLocation NVARCHAR(200) NULL
    -- Add other relevant store attributes as needed
);

CREATE TABLE dbo.Dim_Product (
    ProductID NVARCHAR(50) PRIMARY KEY NOT NULL,
    ProductName NVARCHAR(255) NULL,
    ProductCategory NVARCHAR(100) NULL,
    ProductBrand NVARCHAR(100) NULL
    -- Add other relevant product attributes as needed
);

CREATE TABLE dbo.Dim_Customer (
    CustomerID NVARCHAR(50) PRIMARY KEY NOT NULL,
    CustomerName NVARCHAR(255) NULL,
    CustomerEmail NVARCHAR(255) NULL,
    CustomerSegment NVARCHAR(50) NULL
    -- Add other relevant customer attributes as needed
);

CREATE TABLE dbo.Dim_Employee (
    EmployeeID NVARCHAR(50) PRIMARY KEY NOT NULL,
    EmployeeName NVARCHAR(255) NULL,
    EmployeeRole NVARCHAR(100) NULL,
    ManagerID NVARCHAR(50) NULL
    -- Add other relevant employee attributes as needed
);

-- Fact Table: dbo.Dim_Fact_Sales as described in the image
CREATE TABLE dbo.Dim_Fact_Sales (
    TransactionID NVARCHAR(50) PRIMARY KEY NOT NULL,
    Date DATE NULL,
    Year SMALLINT NULL,
    Quarter TINYINT NULL,
    Month TINYINT NULL,
    MonthName NVARCHAR(50) NULL,
    Week TINYINT NULL,
    Day TINYINT NULL,
    DayName NVARCHAR(50) NULL,
    DayOfWeek TINYINT NULL,
    IsWeekend TINYINT NULL, -- Sticking to tinyint as shown in the image for boolean-like flags
    IsHoliday TINYINT NULL, -- Sticking to tinyint as shown in the image for boolean-like flags
    Time TIME(7) NULL,
    StoreID NVARCHAR(50) NULL,
    ProductID NVARCHAR(50) NULL,
    CustomerID NVARCHAR(50) NULL,
    EmployeeID NVARCHAR(50) NULL,
    Quantity TINYINT NULL, -- Max quantity of 255 per transaction
    UnitPrice FLOAT NULL,
    DiscountPct FLOAT NULL,
    DiscountAmount FLOAT NULL,
    SalesAmount FLOAT NULL,
    TaxAmount FLOAT NULL,
    TotalAmount FLOAT NULL,
    PaymentMethod NVARCHAR(50) NULL,
    ReturnFlag BIT NULL, -- Explicitly 'bit' in the image

    CONSTRAINT FK_Dim_Fact_Sales_Dim_Store FOREIGN KEY (StoreID) REFERENCES dbo.Dim_Store (StoreID),
    CONSTRAINT FK_Dim_Fact_Sales_Dim_Product FOREIGN KEY (ProductID) REFERENCES dbo.Dim_Product (ProductID),
    CONSTRAINT FK_Dim_Fact_Sales_Dim_Customer FOREIGN KEY (CustomerID) REFERENCES dbo.Dim_Customer (CustomerID),
    CONSTRAINT FK_Dim_Fact_Sales_Dim_Employee FOREIGN KEY (EmployeeID) REFERENCES dbo.Dim_Employee (EmployeeID)
);






SELECT
    dfs.Year,
    dfs.Month,
    dfs.MonthName,
    SUM(dfs.SalesAmount) AS TotalSalesAmount,
    SUM(dfs.TaxAmount) AS TotalTaxAmount,
    SUM(dfs.DiscountAmount) AS TotalDiscountAmount,
    SUM(dfs.TotalAmount) AS GrandTotalAmount
FROM
    dbo.Dim_Fact_Sales dfs
WHERE
    dfs.ReturnFlag = 0 -- Exclude returned items (assuming 0 for not returned, 1 for returned)
GROUP BY
    dfs.Year,
    dfs.Month,
    dfs.MonthName
ORDER BY
    dfs.Year,
    dfs.Month;



SELECT TOP 5
    dp.ProductName,
    SUM(dfs.SalesAmount) AS TotalProductSales
FROM
    dbo.Dim_Fact_Sales dfs
JOIN
    dbo.Dim_Product dp ON dfs.ProductID = dp.ProductID
WHERE
    dfs.ReturnFlag = 0 -- Exclude returned items
GROUP BY
    dp.ProductName
ORDER BY
    TotalProductSales DESC;





    SELECT
    dfs.PaymentMethod,
    CASE
        WHEN dfs.IsWeekend = 1 THEN 'Weekend'
        WHEN dfs.IsWeekend = 0 THEN 'Weekday'
        ELSE 'Unknown' -- Handle cases where IsWeekend might be NULL or other values
    END AS DayType,
    SUM(dfs.TotalAmount) AS TotalSalesAmount
FROM
    dbo.Dim_Fact_Sales dfs
WHERE
    dfs.ReturnFlag = 0 -- Exclude returned items
GROUP BY
    dfs.PaymentMethod,
    CASE
        WHEN dfs.IsWeekend = 1 THEN 'Weekend'
        WHEN dfs.IsWeekend = 0 THEN 'Weekday'
        ELSE 'Unknown'
    END
ORDER BY
    dfs.PaymentMethod, DayType;


CREATE TABLE dbo.Dim_Products (
    ProductID NVARCHAR(50) NOT NULL PRIMARY KEY,
    ProductName NVARCHAR(50),
    Category NVARCHAR(50),
    SubCategory NVARCHAR(50),
    Brand NVARCHAR(50),
    UnitOfMeasure NVARCHAR(50),
    UnitPrice FLOAT,
    CostPrice FLOAT,
    SupplierID NVARCHAR(50),
    LaunchDate DATE,
    IsActive BIT
    -- CONSTRAINT FK_Dim_Products_Dim_Suppliers FOREIGN KEY (SupplierID) REFERENCES dbo.Dim_Suppliers (SupplierID)
    -- The FK constraint is commented out because Dim_Suppliers table is not provided.
);



SELECT
        Category,
        COUNT(ProductID) AS NumberOfProducts,
        AVG(UnitPrice) AS AverageUnitPrice,
        AVG(CostPrice) AS AverageCostPrice,
        AVG((UnitPrice - CostPrice)) AS AverageProfitPerUnit,
        AVG((UnitPrice - CostPrice) / UnitPrice) * 100 AS AverageProfitMarginPercentage
    FROM
        dbo.Dim_Products
    WHERE
        IsActive = 1 -- Only consider active products
        AND UnitPrice IS NOT NULL -- Ensure UnitPrice is available for calculation
        AND CostPrice IS NOT NULL -- Ensure CostPrice is available for calculation
        AND UnitPrice > 0 -- Avoid division by zero and ensure valid unit price
    GROUP BY
        Category
    ORDER BY
        AverageProfitMarginPercentage DESC;




SELECT
        ProductName,
        Category,
        SubCategory,
        Brand,
        UnitPrice,
        LaunchDate,
        CASE
            WHEN UnitPrice < 20 THEN 'Budget'
            WHEN UnitPrice >= 20 AND UnitPrice < 100 THEN 'Mid-Range'
            WHEN UnitPrice >= 100 THEN 'Premium'
            ELSE 'Undefined'
        END AS PriceTier
    FROM
        dbo.Dim_Products
    WHERE
        IsActive = 1
        AND LaunchDate >= DATEADD(year, -1, GETDATE()) -- Products launched in the last year
    ORDER BY
        LaunchDate DESC, UnitPrice DESC;


SELECT
        SupplierID,
        COUNT(ProductID) AS NumberOfActiveProducts,
        SUM(UnitPrice) AS TotalPotentialUnitPriceValue -- Sum of UnitPrices as a proxy for value
    FROM
        dbo.Dim_Products
    WHERE
        IsActive = 1
        AND SupplierID IS NOT NULL -- Only include products with an assigned supplier
    GROUP BY
        SupplierID
    ORDER BY
        NumberOfActiveProducts DESC, TotalPotentialUnitPriceValue DESC;




CREATE TABLE dbo.Dim_Stores (
    StoreID       nvarchar(50)  NOT NULL PRIMARY KEY,
    StoreName     nvarchar(50)  NULL,
    Region        nvarchar(50)  NULL,
    City          nvarchar(50)  NULL,
    StoreType     nvarchar(50)  NULL,
    SquareMeters  smallint      NULL,
    OpeningDate   date          NULL,
    Status        nvarchar(50)  NULL,
    ManagerName   nvarchar(50)  NULL
);


SELECT
    Region,
    StoreType,
    COUNT(StoreID) AS NumberOfStores,
    SUM(SquareMeters) AS TotalSquareMeters
FROM
    dbo.Dim_Stores
WHERE
    Status = 'Active' -- Assuming 'Active' is a relevant status for current analysis
GROUP BY
    Region,
    StoreType
ORDER BY
    Region,
    StoreType;



SELECT
    StoreName,
    City,
    OpeningDate,
    ManagerName,
    SquareMeters,
    CASE
        WHEN SquareMeters IS NULL THEN 'Unknown Size'
        WHEN SquareMeters <= 500 THEN 'Small Store'
        WHEN SquareMeters > 500 AND SquareMeters <= 1500 THEN 'Medium Store'
        ELSE 'Large Store'
    END AS StoreSizeCategory
FROM
    dbo.Dim_Stores
WHERE
    OpeningDate >= DATEADD(year, -5, GETDATE()) -- Stores opened in the last 5 years
    AND ManagerName IS NOT NULL -- Only stores with an assigned manager
    AND Status = 'Active' -- Only considering active stores
ORDER BY
    OpeningDate DESC;



SELECT
    Status,
    COUNT(StoreID) AS NumberOfStores,
    AVG(DATEDIFF(year, OpeningDate, GETDATE())) AS AverageStoreAgeInYears
FROM
    dbo.Dim_Stores
WHERE
    OpeningDate IS NOT NULL -- Ensure we only average ages for stores with a known opening date
GROUP BY
    Status
ORDER BY
    NumberOfStores DESC;



CREATE TABLE Dim_Suppliers (
    SupplierID      NVARCHAR(50) PRIMARY KEY, -- Assumed NOT NULL and Primary Key
    SupplierName    NVARCHAR(50) NULL,
    Country         NVARCHAR(50) NULL,
    City            NVARCHAR(50) NULL,
    ContactPerson   NVARCHAR(50) NULL,
    Email           NVARCHAR(50) NULL,
    Phone           BIGINT       NULL,
    PaymentTerms    NVARCHAR(50) NULL,
    LeadTimeDays    TINYINT      NULL,
    Rating          FLOAT        NULL,
    IsActive        BIT          NULL
);




SELECT
    Country,
    COUNT(SupplierID) AS NumberOfActiveSuppliers,
    AVG(Rating) AS AverageRatingOfActiveSuppliers
FROM
    Dim_Suppliers
WHERE
    IsActive = 1
    AND Country IS NOT NULL -- Exclude suppliers with unknown country
GROUP BY
    Country
ORDER BY
    NumberOfActiveSuppliers DESC, AverageRatingOfActiveSuppliers DESC;



SELECT
    SupplierName,
    Country,
    LeadTimeDays,
    Rating,
    CASE
        WHEN LeadTimeDays <= 7 AND Rating >= 4.0 THEN 'Premium Supplier' -- Fast Lead Time & High Rating
        WHEN LeadTimeDays <= 14 AND Rating >= 3.0 THEN 'Standard Supplier' -- Medium Lead Time & Good Rating
        WHEN LeadTimeDays > 14 AND Rating < 3.0 THEN 'Underperforming Supplier' -- Slow Lead Time & Low Rating
        WHEN LeadTimeDays IS NULL OR Rating IS NULL THEN 'Data Incomplete'
        ELSE 'Other Supplier'
    END AS SupplierPerformanceCategory
FROM
    Dim_Suppliers
WHERE
    IsActive = 1
ORDER BY
    SupplierPerformanceCategory, LeadTimeDays, Rating DESC;



SELECT
    SupplierName,
    Country,
    ContactPerson,
    Email,
    Phone,
    PaymentTerms,
    LeadTimeDays,
    Rating,
    IsActive
FROM
    Dim_Suppliers
WHERE
    IsActive = 0 -- Inactive suppliers
    OR (Rating IS NOT NULL AND Rating < 2.5) -- Suppliers with a low rating
    OR (LeadTimeDays IS NOT NULL AND LeadTimeDays > 30) -- Suppliers with very long lead times
ORDER BY
    IsActive, Rating, LeadTimeDays DESC;



CREATE TABLE dbo.Dim_Customers (
    CustomerID          nvarchar(50)    PRIMARY KEY NOT NULL,
    FirstName           nvarchar(50)    NULL,
    LastName            nvarchar(50)    NULL,
    FullName            nvarchar(50)    NULL,
    Gender              nvarchar(50)    NULL,
    Email               nvarchar(50)    NULL,
    Phone               bigint          NULL,
    City                nvarchar(50)    NULL,
    Region              nvarchar(50)    NULL,
    DateOfBirth         date            NULL,
    RegistrationDate    date            NULL,
    MembershipTier      nvarchar(50)    NULL,
    IsActive            bit             NULL
);




SELECT
        Region,
        MembershipTier,
        COUNT(CustomerID) AS NumberOfCustomers
    FROM
        dbo.Dim_Customers
    WHERE
        IsActive = 1 -- Only count active customers
    GROUP BY
        Region,
        MembershipTier
    ORDER BY
        Region,
        MembershipTier;



SELECT
        CustomerID,
        FullName,
        DateOfBirth,
        CASE
            WHEN DateOfBirth IS NULL THEN 'Unknown'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) < 18 THEN 'Under 18'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) BETWEEN 18 AND 24 THEN '18-24'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) BETWEEN 25 AND 34 THEN '25-34'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) BETWEEN 35 AND 44 THEN '35-44'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) BETWEEN 45 AND 54 THEN '45-54'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END AS AgeGroup
    FROM
        dbo.Dim_Customers
    WHERE
        IsActive = 1
    ORDER BY
        DateOfBirth DESC;



SELECT
        CustomerID,
        FullName,
        Email,
        RegistrationDate,
        MembershipTier,
        City,
        Region
    FROM
        dbo.Dim_Customers
    WHERE
        MembershipTier = 'Premium'
        AND IsActive = 1
        AND RegistrationDate >= DATEADD(year, -1, GETDATE()) -- Registered in the last 12 months
    ORDER BY
        RegistrationDate DESC;


CREATE TABLE dbo.Dim_Employees (
    EmployeeID      nvarchar(50) NULL, -- Although specified as NULL, in a real-world scenario this would typically be NOT NULL and a PRIMARY KEY.
    FirstName       nvarchar(50) NULL,
    LastName        nvarchar(50) NULL,
    FullName        nvarchar(50) NULL,
    Gender          nvarchar(50) NULL,
    Email           nvarchar(50) NULL,
    Phone           bigint       NULL,
    StoreID         nvarchar(50) NULL, -- Likely a Foreign Key to a Dim_Stores table
    Department      nvarchar(50) NULL,
    JobTitle        nvarchar(50) NULL,
    HireDate        date         NULL,
    Salary          smallint     NULL, -- Note: smallint implies a maximum salary of 32,767.
    EmploymentType  nvarchar(50) NULL,
    IsActive        bit          NULL
);



-- Query 1: Calculate the average salary and employee count per department for active employees
-- (Note: Salary is smallint, so average might be low. Casting to decimal for precision.)
SELECT
    Department,
    COUNT(EmployeeID) AS NumberOfEmployees,
    AVG(CAST(Salary AS DECIMAL(10, 2))) AS AverageSalary
FROM
    dbo.Dim_Employees
WHERE
    IsActive = 1 -- Only consider active employees
GROUP BY
    Department
ORDER BY
    AverageSalary DESC;

-- Query 2: List employees with their tenure status and overall employment status
-- based on HireDate and IsActive flag.
SELECT
    EmployeeID,
    FullName,
    Department,
    JobTitle,
    HireDate,
    CASE
        WHEN HireDate IS NULL THEN 'Hire Date Unknown'
        WHEN DATEDIFF(year, HireDate, GETDATE()) < 1 THEN 'New Employee (< 1 year)'
        WHEN DATEDIFF(year, HireDate, GETDATE()) BETWEEN 1 AND 5 THEN 'Established Employee (1-5 years)'
        ELSE 'Long-Term Employee (> 5 years)'
    END AS TenureStatus,
    CASE
        WHEN IsActive = 1 THEN 'Active'
        WHEN IsActive = 0 THEN 'Inactive'
        ELSE 'Status Unknown'
    END AS EmploymentStatus
FROM
    dbo.Dim_Employees
ORDER BY
    HireDate DESC;

-- Query 3: Find the top 5 highest-paid active employees in the 'Sales' department
SELECT TOP 5
    FullName,
    JobTitle,
    Salary,
    HireDate,
    Email,
    Phone
FROM
    dbo.Dim_Employees
WHERE
    Department = 'Sales' AND IsActive = 1
ORDER BY
    Salary DESC;



