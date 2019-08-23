package demo.geode.fncallfn;

import org.apache.geode.cache.Region;
import org.apache.geode.cache.execute.Function;
import org.apache.geode.cache.execute.FunctionContext;
import org.apache.geode.cache.execute.FunctionService;
import org.apache.geode.cache.execute.RegionFunctionContext;
import org.apache.geode.internal.logging.LogService;
import org.apache.logging.log4j.Logger;

import java.util.*;

public class PrettyPrintFunction implements Function {
    private static final Logger logger = LogService.getLogger();

    @Override
    public void execute(FunctionContext context) {
        if (context instanceof RegionFunctionContext) {
            logger.info("InitialFunction.execute");
            RegionFunctionContext rfc = (RegionFunctionContext) context;
            Region region = rfc.getDataSet();
            Object args = rfc.getArguments();
            Set<String> keys = null;
            if (args == null) {
                keys = Collections.EMPTY_SET;
            } else if (args instanceof String) {
                keys = Collections.singleton((String) args);
            } else {
                Object[] objArray = (Object[]) args;
                String[] stringArray = Arrays.copyOf(objArray, objArray.length, String[].class);
                keys = new HashSet<>(Arrays.asList(stringArray));
            }
            Collection<Map<String, String>> collection =
                    (Collection<Map<String, String>>) FunctionService.onRegion(region)
                            .withFilter(keys)
                            .execute(PartitionedFunction.ID).getResult();
            Map<String, String> result = new HashMap<>();
            collection.forEach((map) -> {
                result.putAll(map);
            });
            rfc.getResultSender().lastResult(result);
        } else {
            throw new RuntimeException("Not Called on a region");
        }
    }

    @Override
    public boolean hasResult() {
        return true;
    }

    @Override
    public String getId() {
        return "PrettyPrintFunction";
    }
}
