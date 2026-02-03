public class StringListTest {
    public static List<String> generateStringList(Integer n){
        List<String> strings = new List<String>();
        for(Integer i = 0; i < n; i++){
            strings.add('Test ' + i);
            System.debug(strings);
        }
        return strings;
    }
}