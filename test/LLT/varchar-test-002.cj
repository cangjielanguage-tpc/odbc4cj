// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package odbc
from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*
from std import unittest.*
from std import unittest.testmacro.*

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
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data varchar(50) NOT NULL, datanull varchar(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlVarchar("萨菲罗斯经历过是"), SqlNullableVarchar(None)])
        println(rowCount.rowCount)
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
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
    }
}
