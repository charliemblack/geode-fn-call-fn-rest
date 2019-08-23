package demo.geode.fncallfn;

import org.apache.geode.cache.Region;
import org.apache.geode.cache.execute.Function;
import org.apache.geode.cache.execute.FunctionContext;
import org.apache.geode.cache.execute.RegionFunctionContext;
import org.apache.geode.internal.logging.LogService;
import org.apache.logging.log4j.Logger;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class PartitionedFunction implements Function {
    private static Logger logger = LogService.getLogger();
    public static final String ID = "PartitionedFunction";

    @Override
    public boolean hasResult() {
        return true;
    }

    @Override
    public void execute(FunctionContext context) {
        if (context instanceof RegionFunctionContext) {
            logger.info("PartitionedFunction.execute");
            RegionFunctionContext rfc = (RegionFunctionContext) context;
            Region<String, String> region = rfc.getDataSet();
            Set<String> keys = (Set<String>) rfc.getFilter();
            logger.info("filter - " + keys.toString());
            Map<String, String> results = new HashMap<>();
            keys.forEach((key) -> {
                results.put(key, region.get(key));
            });
            rfc.getResultSender().lastResult(results);
        } else {
            throw new RuntimeException("Not Called on a region");
        }
    }

    @Override
    public String getId() {

        return ID;
    }

    @Override
    public boolean optimizeForWrite() {
        return true;
    }
}
