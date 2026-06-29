package io.bitnomio.coeff.simulator;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class TaxEngineTest {

    private final List<TaxEngine.TaxBracket> brackets = List.of(
        new TaxEngine.TaxBracket(0, 12450, 0.095),
        new TaxEngine.TaxBracket(12450, 20200, 0.12),
        new TaxEngine.TaxBracket(20200, 35200, 0.15),
        new TaxEngine.TaxBracket(35200, 60000, 0.185),
        new TaxEngine.TaxBracket(60000, Double.MAX_VALUE, 0.225)
    );

    private final TaxEngine.Config config = new TaxEngine.Config(5550, 2400, 1150, 3000, 2150, 0.0635);

    @Test
    void calculateIRPF_typicalSalary() {
        var engine = new TaxEngine(brackets, config);
        var family = engine.calculateFamilyDeductions(0, 0, 0, false);
        var result = engine.calculateIRPF(48000, 48000, family);
        assertTrue(result.total() > 0);
        assertTrue(result.rate() > 0);
    }

    @Test
    void calculateIRPF_withChildren() {
        var engine = new TaxEngine(brackets, config);
        var family = engine.calculateFamilyDeductions(2, 0, 0, false);
        var result = engine.calculateIRPF(48000, 48000, family);
        var noKids = engine.calculateIRPF(48000, 48000, engine.calculateFamilyDeductions(0, 0, 0, false));
        assertTrue(result.total() < noKids.total(), "IRPF should be lower with children");
    }

    @Test
    void calculateIRPF_married() {
        var engine = new TaxEngine(brackets, config);
        var single = engine.calculateFamilyDeductions(0, 0, 0, false);
        var married = engine.calculateFamilyDeductions(0, 0, 0, true);
        assertTrue(married.total() > single.total(), "Married deduction should be larger");
    }

    @Test
    void calculateSS_flatRate() {
        var engine = new TaxEngine(brackets, config);
        var result = engine.calculateSS(48000);
        assertEquals(0.0635, result.rate(), 0.0001);
        assertTrue(result.annual() > 0);
    }

    @Test
    void calculateSS_categoryCapped() {
        var categories = List.of(
            new TaxEngine.SsCategory("Ingenieros y Licenciados", 1629.3, 4139.4, 0.0635)
        );
        var engine = new TaxEngine(brackets, null, categories, config);
        var result = engine.calculateSS(48000, "Ingenieros y Licenciados");
        assertTrue(result.annual() <= 4139.4 * 12 * 0.0635);
    }

    @Test
    void calculateSS_emptyCategoriesFallsBack() {
        var engine = new TaxEngine(brackets, config);
        var result = engine.calculateSS(36000);
        assertEquals(0.0635, result.rate());
    }

    @Test
    void calculateIRPF_zeroIncome() {
        var engine = new TaxEngine(brackets, config);
        var family = engine.calculateFamilyDeductions(0, 0, 0, false);
        var result = engine.calculateIRPF(0, 0, family);
        assertEquals(0, result.total());
    }

    @Test
    void calculateFamilyDeductions_defaults() {
        var engine = new TaxEngine(brackets, config);
        var result = engine.calculateFamilyDeductions(0, 0, 0, false);
        assertEquals(5550, result.base());
        assertEquals(0, result.spouse());
        assertEquals(0, result.descendants());
        assertEquals(5550, result.total());
    }

    @Test
    void calculateFamilyDeductions_withDependents() {
        var engine = new TaxEngine(brackets, config);
        var result = engine.calculateFamilyDeductions(2, 1, 1, true);
        assertEquals(5550, result.base());
        assertEquals(2150, result.spouse());
        assertEquals(4800, result.descendants());
        assertEquals(1150, result.ascendants());
        assertEquals(3000, result.disability());
        assertEquals(16650, result.total());
    }

    @Test
    void calculateIRPF_dualBrackets() {
        var regional = List.of(
            new TaxEngine.TaxBracket(0, 12450, 0.10),
            new TaxEngine.TaxBracket(12450, Double.MAX_VALUE, 0.14)
        );
        var engine = new TaxEngine(brackets, regional, config);
        var family = engine.calculateFamilyDeductions(0, 0, 0, false);
        var result = engine.calculateIRPF(30000, 30000, family);
        assertTrue(result.total() > 0);
    }
}
