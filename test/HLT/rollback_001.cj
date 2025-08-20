//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

@Test
public class OdbcTest {
    init() {
    }
    
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var tran = conn.createTransaction()
        tran.begin()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        tran.commit()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data int NOT NULL, datanull int)")
        rowCount = prepareStatement.update()
        tran.commit()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(123,123)")
        tran.rollback()
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        prepareStatement.set<Int32>(0, 456)
        prepareStatement.set<Option<Int32>>(1, Option<Int32>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        queryResult.next()
        tran.commit()
        @Assert("SqlInt32", queryResult.columnInfos[0].typeName)
        @Assert("SqlInt32", queryResult.columnInfos[1].typeName)
        @Assert(456, queryResult.get<Int32>(0))
        @Assert(None, queryResult.getOrNull<Int32>(1))
        queryResult.close()
    }
}
