package io.bitnomio.coeff.consultant.domain;

import io.bitnomio.coeff.shared.domain.*;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ConsultantTest {

    @Test
    void createConstructsTypedValueObjects() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, 1000.0);

        assertEquals("Alice", c.name());
        assertEquals("ClientA", c.client());
        assertEquals("Engineer", c.position());

        // Verify typed value objects
        assertEquals(1.5, c.coef().value(), 0.0001);
        assertEquals(400.0, c.tariff().value(), 0.0001);
        assertEquals(1000.0, c.fees().value(), 0.0001);

        // Null fields remain null
        assertNull(c.coefPercentage());
        assertNull(c.coefMargin());
        assertNull(c.managerBonus());
        assertNull(c.grossMonthlySalary());
        assertNull(c.netMonthlySalary());
        assertNull(c.netAnnualSalary());
        assertNull(c.monthlySs());
        assertNull(c.monthlyIrpf());
        assertNull(c.irpfRate());
        assertNull(c.ssRate());

        assertEquals(ProfitabilityStatus.INSUFFICIENT_DATA, c.profitabilityStatus());
        assertNull(c.id());
        assertNotNull(c.createdAt());
        assertNotNull(c.updatedAt());
    }

    @Test
    void createWithNegativeFeesThrows() {
        assertThrows(IllegalArgumentException.class,
            () -> Consultant.create("A", "C", "P", 400.0, 1.5, "2024-01-01", null, -1.0));
    }

    @Test
    void createWithNegativeTariffThrows() {
        assertThrows(IllegalArgumentException.class,
            () -> Consultant.create("A", "C", "P", -400.0, 1.5, "2024-01-01", null, null));
    }

    @Test
    void createWithNegativeCoefThrows() {
        assertThrows(IllegalArgumentException.class,
            () -> Consultant.create("A", "C", "P", 400.0, -1.5, "2024-01-01", null, null));
    }

    @Test
    void updatePreservesExistingStateAndChangesFields() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, 1000.0);
        var updated = c.update("Alice", "ClientB", "Senior Engineer", 500.0, 2.0, "2024-01-01", null, 2000.0);

        assertEquals("Alice", updated.name());
        assertEquals("ClientB", updated.client());
        assertEquals("Senior Engineer", updated.position());
        assertEquals(2.0, updated.coef().value(), 0.0001);
        assertEquals(500.0, updated.tariff().value(), 0.0001);
        assertEquals(2000.0, updated.fees().value(), 0.0001);

        // Nullable VOs preserved as null (none were set)
        assertNull(updated.coefPercentage());
        assertNull(updated.managerBonus());

        // ID and createdAt preserved
        assertEquals(c.id(), updated.id());
        assertEquals(c.createdAt(), updated.createdAt());
        assertTrue(updated.updatedAt().compareTo(c.updatedAt()) >= 0);
    }

    @Test
    void daysInRoleReturnsPositive() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, null);
        assertTrue(c.daysInRole() >= 0);
    }

    @Test
    void isActiveReturnsTrueWhenNoEndDate() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, null);
        assertTrue(c.isActive());
    }

    @Test
    void isActiveReturnsFalseWhenPastEndDate() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", "2024-01-01", null);
        assertFalse(c.isActive());
    }

    @Test
    void canEarnManagerBonusReturnsBoolean() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, null);
        // Any result is fine as long as it doesn't throw
        assertNotNull(c.canEarnManagerBonus(2026, 6));
    }

    @Test
    void coefAccessorReturnsTypedCoef() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, null);
        assertInstanceOf(Coef.class, c.coef());
        assertEquals(1.5, c.coef().value(), 0.0001);
    }

    @Test
    void tariffAccessorReturnsTypedTariff() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, null);
        assertInstanceOf(Tariff.class, c.tariff());
        assertEquals(400.0, c.tariff().value(), 0.0001);
    }

    @Test
    void feesAccessorReturnsTypedMoney() {
        var c = Consultant.create("Alice", "ClientA", "Engineer", 400.0, 1.5, "2024-01-01", null, 500.0);
        assertInstanceOf(Money.class, c.fees());
        assertEquals(500.0, c.fees().value(), 0.0001);
    }

    @Test
    void allFieldsConstructorWithVOs() {
        var c = new Consultant(
            1L, "Bob", "ClientX", "Dev",
            new Coef(2.0), new Tariff(600.0), "2024-06-01", null,
            new Money(2000.0), new CoefPct(0.8), new CoefPct(0.1), new Bonus(5000.0),
            "{}", ProfitabilityStatus.PROFITABLE,
            new Money(50000.0), new Money(35000.0), new Money(420000.0),
            new Money(3000.0), new Money(4000.0), new TaxRate(0.2), new TaxRate(0.0635),
            "stable", "2024-06-01", "2024-06-01");

        assertEquals(1L, c.id());
        assertEquals(2.0, c.coef().value(), 0.0001);
        assertEquals(600.0, c.tariff().value(), 0.0001);
        assertEquals(2000.0, c.fees().value(), 0.0001);
        assertEquals(0.8, c.coefPercentage().value(), 0.0001);
        assertEquals(0.1, c.coefMargin().value(), 0.0001);
        assertEquals(5000.0, c.managerBonus().value(), 0.0001);
        assertEquals(50000.0, c.grossMonthlySalary().value(), 0.0001);
        assertEquals(35000.0, c.netMonthlySalary().value(), 0.0001);
        assertEquals(420000.0, c.netAnnualSalary().value(), 0.0001);
        assertEquals(3000.0, c.monthlySs().value(), 0.0001);
        assertEquals(4000.0, c.monthlyIrpf().value(), 0.0001);
        assertEquals(0.2, c.irpfRate().value(), 0.0001);
        assertEquals(0.0635, c.ssRate().value(), 0.0001);
        assertEquals(ProfitabilityStatus.PROFITABLE, c.profitabilityStatus());
    }
}
