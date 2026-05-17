package io.bitnomio.coeff.client;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Singleton
public class ClientService {

    private final Jdbi jdbi;

    @Inject
    public ClientService(Jdbi jdbi) { this.jdbi = jdbi; }

    public List<Map<String, Object>> summary() {
        return jdbi.withHandle(h -> h.createQuery(
            "SELECT client, COUNT(*) as positionCount, GROUP_CONCAT(name) as consultants FROM consultants GROUP BY client ORDER BY client")
            .mapToMap().list());
    }

    public List<Map<String, Object>> financial() {
        return jdbi.withHandle(h -> {
            var cdm = h.createQuery("SELECT COALESCE(value,'21') FROM settings WHERE key='fiscal.coefDaysMonth'").mapTo(String.class).findOne().orElse("21");
            var rows = h.createQuery(
                "SELECT * FROM v_client_financials ORDER BY total_fees DESC").mapToMap().list();
            var result = new ArrayList<Map<String, Object>>();
            for (var r : rows) {
                var m = new HashMap<String, Object>();
                m.put("client", r.get("client"));
                m.put("consultants", r.get("consultant_count"));
                var totalFees = ((Number) r.get("total_fees")).doubleValue();
                var daysMonth = Double.parseDouble(cdm);
                m.put("daily", totalFees / daysMonth);
                m.put("monthly", totalFees);
                m.put("annual", totalFees * 12);
                m.put("fees", r.get("total_fees"));
                m.put("avgCoef", 0.0);
                m.put("margin", r.get("total_margin"));
                m.put("bonus", r.get("total_bonus"));
                m.put("avgTenureDays", r.get("avg_tenure"));
                m.put("maxTenureDays", r.get("max_tenure"));
                result.add(m);
            }
            return result;
        });
    }
}
