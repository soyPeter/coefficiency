package io.bitnomio.coeff.simulator;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.bitnomio.coeff.shared.exceptions.BadRequestException;
import io.bitnomio.coeff.shared.util.SettingsHelper;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api/simulator")
public class SimulatorController {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final SimulatorService simulatorService;
    private final Jdbi jdbi;

    @Inject
    public SimulatorController(SimulatorService simulatorService, Jdbi jdbi) {
        this.simulatorService = simulatorService;
        this.jdbi = jdbi;
    }

    @GET @Path("/defaults")
    public Map<String, Object> defaults() {
        var concepts = jdbi.withHandle(h ->
            h.createQuery("SELECT * FROM cost_concepts ORDER BY name").mapToMap().list());
        var workingDays = loadWorkingDays();
        int totalDays = workingDays.stream().mapToInt(Integer::intValue).sum();
        int coefDaysMonth = SettingsHelper.readIntOrDefault(jdbi, "fiscal.coefDaysMonth", (int) Math.ceil((double) totalDays / 12.0));
        int coefDaysYear = SettingsHelper.readIntOrDefault(jdbi, "fiscal.coefDaysYear", totalDays);
        return Map.of(
            "categories", TaxEngine.CATEGORIES,
            "schedules", TaxEngine.BONUS_SCHEDULES,
            "coefDaysMonth", coefDaysMonth,
            "coefDaysYear", coefDaysYear,
            "concepts", concepts,
            "workingDays", workingDays
        );
    }

    @POST @Path("/calculate")
    public Map<String, Object> calculate(SimulatorInput input) {
        validateInput(input);
        var brackets = loadBrackets("fiscal.irpf_brackets");
        var regionalBrackets = loadBrackets("fiscal.irpf_regional_brackets");
        var ssCategories = loadSsCategories();

        var taxConfig = new TaxEngine.Config(
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.personal_minimum", 5550),
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.deduction_child", 2400),
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.deduction_asc", 1150),
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.deduction_dis", 3000),
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.deduction_spouse", 2150),
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.ss_rate", 0.0635)
        );

        var engine = new TaxEngine(brackets, regionalBrackets, ssCategories, taxConfig);
        double lirpfExpenses = SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.lirpf_expenses", 2000);

        var workingDays = loadWorkingDays();
        int totalDays = workingDays.stream().mapToInt(Integer::intValue).sum();
        int coefDaysMonth = SettingsHelper.readIntOrDefault(jdbi, "fiscal.coefDaysMonth", (int) Math.ceil((double) totalDays / 12.0));
        int coefDaysYear = SettingsHelper.readIntOrDefault(jdbi, "fiscal.coefDaysYear", totalDays);

        var coefConfig = new SimulatorService.CoefConfig(
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.coef_multiplier", 1.7),
            SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.mng_bonus_pct", 0.05),
            SettingsHelper.readIntOrDefault(jdbi, "fiscal.insurance_months", 6),
            SettingsHelper.readIntOrDefault(jdbi, "fiscal.meal_card_days", 22),
            coefDaysMonth,
            coefDaysYear
        );

        var result = simulatorService.calculate(input, engine, lirpfExpenses, coefConfig);
        return Map.of("ok", true, "result", result);
    }

    private List<TaxEngine.TaxBracket> loadBrackets(String key) {
        var json = SettingsHelper.getSetting(jdbi, key).orElse(null);
        if (json == null) {
            return List.of(
                new TaxEngine.TaxBracket(0, 12450, 0.095),
                new TaxEngine.TaxBracket(12450, 20200, 0.12),
                new TaxEngine.TaxBracket(20200, 35200, 0.15),
                new TaxEngine.TaxBracket(35200, 60000, 0.185),
                new TaxEngine.TaxBracket(60000, Double.MAX_VALUE, 0.225)
            );
        }
        try {
            List<Map<String, Object>> raw = MAPPER
                .readValue(json, new TypeReference<List<Map<String, Object>>>() {});
            return raw.stream().map(m -> new TaxEngine.TaxBracket(
                ((Number) m.get("from")).doubleValue(),
                ((Number) m.get("to")).doubleValue(),
                ((Number) m.get("rate")).doubleValue()
            )).toList();
        } catch (Exception e) {
            return List.of();
        }
    }

    private List<TaxEngine.SsCategory> loadSsCategories() {
        var json = SettingsHelper.getSetting(jdbi, "fiscal.ss_config").orElse(null);
        if (json == null) return List.of();
        try {
            List<Map<String, Object>> raw = MAPPER
                .readValue(json, new TypeReference<List<Map<String, Object>>>() {});
            return raw.stream().map(m -> new TaxEngine.SsCategory(
                (String) m.get("category"),
                ((Number) m.get("baseMin")).doubleValue(),
                ((Number) m.get("baseMax")).doubleValue(),
                ((Number) m.get("rate")).doubleValue()
            )).toList();
        } catch (Exception e) {
            return List.of();
        }
    }

    private List<Integer> loadWorkingDays() {
        var json = SettingsHelper.getSetting(jdbi, "fiscal.workingDays").orElse(null);
        if (json == null) return List.of(20, 19, 23, 19, 21, 22, 21, 22, 22, 20, 21, 19);
        try {
            return MAPPER.readValue(json, new TypeReference<List<Integer>>() {});
        } catch (Exception e) {
            return List.of();
        }
    }

    // REQ-VALIDATE-001: validate simulator input parameters
    private static void validateInput(SimulatorInput input) {
        var errors = new java.util.ArrayList<String>();
        if (input.fees() != null && input.fees() < 0) errors.add("fees must be non-negative");
        if (input.age() != null && (input.age() < 0 || input.age() > 120)) errors.add("age must be between 0 and 120");
        if (input.grossAnnualSalary() != null && input.grossAnnualSalary() < 0) errors.add("grossAnnualSalary must be non-negative");
        if (input.dailyMealCard() != null && input.dailyMealCard() < 0) errors.add("dailyMealCard must be non-negative");
        if (input.annualPerformanceBonus() != null && input.annualPerformanceBonus() < 0) errors.add("annualPerformanceBonus must be non-negative");
        if (input.annualChildSupport() != null && input.annualChildSupport() < 0) errors.add("annualChildSupport must be non-negative");
        if (input.annualTraining() != null && input.annualTraining() < 0) errors.add("annualTraining must be non-negative");
        if (input.monthlyLaptop() != null && input.monthlyLaptop() < 0) errors.add("monthlyLaptop must be non-negative");
        if (input.monthlyHealthInsurance() != null && input.monthlyHealthInsurance() < 0) errors.add("monthlyHealthInsurance must be non-negative");
        if (input.monthlyExtraIT() != null && input.monthlyExtraIT() < 0) errors.add("monthlyExtraIT must be non-negative");
        if (input.monthlyLicenses() != null && input.monthlyLicenses() < 0) errors.add("monthlyLicenses must be non-negative");
        if (input.otherCosts() != null && input.otherCosts() < 0) errors.add("otherCosts must be non-negative");
        if (input.children() != null && input.children() < 0) errors.add("children must be non-negative");
        if (input.ascendants() != null && input.ascendants() < 0) errors.add("ascendants must be non-negative");
        if (input.disability() != null && input.disability() < 0) errors.add("disability must be non-negative");
        if (input.otherIncomeIRPF() != null && input.otherIncomeIRPF() < 0) errors.add("otherIncomeIRPF must be non-negative");
        if (input.otherIncomeSS() != null && input.otherIncomeSS() < 0) errors.add("otherIncomeSS must be non-negative");
        if (input.taxFreeRemuneration() != null && input.taxFreeRemuneration() < 0) errors.add("taxFreeRemuneration must be non-negative");
        if (input.annualWorkdays() != null && input.annualWorkdays() < 0) errors.add("annualWorkdays must be non-negative");
        if (input.workingDays() != null) {
            for (var wd : input.workingDays()) {
                if (wd < 0 || wd > 31) { errors.add("each working day must be between 0 and 31"); break; }
            }
        }
        if (!errors.isEmpty()) throw new BadRequestException(String.join("; ", errors));
    }
}
