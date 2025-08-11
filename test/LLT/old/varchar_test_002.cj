// EXEC: cjc %import-path %L %l %f
// EXEC: ./main


import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*
import std.unittest.*
import std.unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data varchar(50) NOT NULL, datanull varchar(20))")
        rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        rowCount = prepareStatement.update([SqlVarchar("萨菲罗斯经历过是"), SqlNullableVarchar(None)])
        println(rowCount.rowCount)
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query([])
        var arr: Array<SqlDbType> = [SqlVarchar("abc"), SqlNullableVarchar(None)]
        queryResult.next(arr)
        @Assert("SqlVarchar", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlVarchar => @Assert("萨菲罗斯经历过是", v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableVarchar", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableVarchar => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
